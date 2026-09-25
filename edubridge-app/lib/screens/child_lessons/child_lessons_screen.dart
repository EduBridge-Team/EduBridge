// lib/screens/child_lessons/child_lessons_screen.dart
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../services/api_service.dart';
import '../../services/tts_service.dart';
import '../../services/simple_language_service.dart';
import '../../services/reward_service.dart';
import '../../theme.dart';
import '../../utils/adaptive_helper.dart';
import '../../widgets/accessibility/adaptive_button.dart';
import '../../widgets/accessibility/adaptive_card.dart';
import '../../widgets/accessibility/adaptive_text.dart';
import '../../widgets/accessibility/adaptive_video_player.dart';
import '../../widgets/accessibility/adaptive_wrapper.dart';
import '../../widgets/accessibility/audio_timer.dart';
import '../../widgets/accessibility/brain_break_overlay.dart';
import '../../widgets/accessibility/emergency_button.dart';
import '../../widgets/accessibility/visual_celebration.dart';
import '../../widgets/accessibility/visual_timeline.dart';
import '../../widgets/accessibility/visual_timer.dart';
import '../child_accessibility/child_accessibility_settings_screen.dart';
import '../child_progress_screen.dart';
import '../educational_games_screen.dart';
import '../assistant_screen.dart';

part 'child_lessons_header.dart';
part 'child_lessons_card.dart';
part 'child_lessons_detail_modal.dart';
part 'child_lessons_samples.dart';
part 'child_lessons_actions.dart';

class ChildLessonsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int age;
  final String? disabilityType;
  final String? parentPhone;

  const ChildLessonsScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.age = 8,
    this.disabilityType,
    this.parentPhone,
  });

  @override
  State<ChildLessonsScreen> createState() => _ChildLessonsScreenState();
}

class _ChildLessonsScreenState extends State<ChildLessonsScreen> {
  List _lessons = [];
  bool _loading = true;
  String? _error;

  final Set<int> _doneLessonIds = {};
  int? _savingLessonId;
  bool _canMarkDone = false;

  int _timerCycle = 0;
  int _stars = 0;

  int? _speakingLessonId;
  final AudioPlayer _lessonAudioPlayer = AudioPlayer();
  String? _activeAudioUrl;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadLessons();
    _loadStars();

    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityType,
      forceReload: true,
    );
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _lessonAudioPlayer.dispose();
    AccessibilityService.instance.setActiveChild(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrainBreakScheduler(
      profileListenable: AccessibilityService.instance.profile,
      child: AdaptiveWrapper(
        screenTitle: 'دروس ${widget.childName}',
        child: Scaffold(
          appBar: buildChildLessonsAppBar(
            context: context,
            childName: widget.childName,
            stars: _stars,
            onOpenSettings: _openSettings,
            onOpenProgress: _openProgress,
          ),
          body: RefreshIndicator(
            onRefresh: _loadLessons,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.error, size: 60, color: AppColors.red),
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveText(
                _error!,
                textAlign: TextAlign.center,
                color: AppColors.red,
              ),
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveButton(
                label: 'إعادة المحاولة',
                icon: AppIcons.refresh,
                onPressed: _loadLessons,
              ),
            ],
          ),
        ),
      );
    }

    final profile = AccessibilityService.instance.profile.value;
    final lessonsToShow =
        _lessons.isEmpty ? getSampleLessons(profile.type) : _lessons;
    final showSampleBanner = _lessons.isEmpty;

    return ListView.builder(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      itemCount: lessonsToShow.length + (showSampleBanner ? 2 : 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return buildAdaptiveHeader(
            context: context,
            childName: widget.childName,
            parentPhone: widget.parentPhone,
            canMarkDone: _canMarkDone,
            timerCycle: _timerCycle,
            onOpenGames: _openGames,
            onTimerFinished: () => setState(() => _timerCycle++),
          );
        }

        if (showSampleBanner && i == 1) {
          return buildSampleBanner();
        }

        final lessonIndex = i - (showSampleBanner ? 2 : 1);
        return buildLessonCard(
          context: context,
          lesson: lessonsToShow[lessonIndex],
          doneLessonIds: _doneLessonIds,
          speakingLessonId: _speakingLessonId,
          savingLessonId: _savingLessonId,
          canMarkDone: _canMarkDone,
          onOpenLesson: _openLesson,
          onToggleSpeak: _toggleSpeak,
          onMarkDone: _markLessonDone,
        );
      },
    );
  }
}