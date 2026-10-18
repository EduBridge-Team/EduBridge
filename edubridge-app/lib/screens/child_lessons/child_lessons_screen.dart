import '../../widgets/accessibility/child_adaptation_scope.dart';
// lib/screens/child_lessons/child_lessons_screen.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../services/api_service.dart';
import '../../features/lessons/data/child_lessons_repository.dart';
import '../../services/tts_service.dart';
import '../../services/simple_language_service.dart';
import '../../services/reward_service.dart';
import '../../theme.dart';
import '../../utils/adaptive_helper.dart';
import '../../utils/adaptive_feedback_policy.dart';
import '../../widgets/accessibility/adaptive_button.dart';
import '../../widgets/accessibility/alt_text_image.dart';
import '../../widgets/accessibility/step_by_step_lesson.dart';
import '../../widgets/accessibility/adaptive_card.dart';
import '../../widgets/accessibility/simple_icons_grid.dart';
import '../../widgets/accessibility/adaptive_text.dart';
import '../../widgets/accessibility/adaptive_video_player.dart';
import '../../widgets/accessibility/adaptive_wrapper.dart';
import '../../widgets/accessibility/audio_timer.dart';
import '../../widgets/accessibility/brain_break_overlay.dart';
import '../../widgets/accessibility/emergency_button.dart';
import '../../widgets/accessibility/visual_celebration.dart';
import '../../widgets/accessibility/visual_timeline.dart';
import '../../widgets/accessibility/visual_timer.dart';
import '../../widgets/lesson_rating_sheet.dart';
import '../child_accessibility/child_accessibility_settings_screen.dart';
import '../child_progress_screen.dart';
import '../educational_games_screen.dart';
import '../assistant_screen.dart';
import '../case_discussion/case_discussion_screen.dart';

part 'child_lessons_header.dart';
part 'child_lessons_card.dart';
part 'child_lessons_detail_modal.dart';
part 'child_lessons_samples.dart';
part 'child_lessons_actions.dart';
part 'child_lessons_s10.dart';

class ChildLessonsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int age;
  final String? disabilityType;
  final String? parentPhone;
  final bool specialistS10;

  const ChildLessonsScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.age = 8,
    this.disabilityType,
    this.parentPhone,
    this.specialistS10 = false,
  });

  @override
  State<ChildLessonsScreen> createState() => _ChildLessonsScreenState();
}

class _ChildLessonsScreenState extends State<ChildLessonsScreen> {
  final _lessonsRepository = ChildLessonsRepository();
  List _lessons = [];
  bool _loading = true;
  String? _error;

  final Set<int> _doneLessonIds = {};
  int? _savingLessonId;
  bool _canMarkDone = false;
  bool _isSpecialist = false;

  int _timerCycle = 0;
  int _stars = 0;
  String? _specialistPhone;

  int? _speakingLessonId;
  final AudioPlayer _lessonAudioPlayer = AudioPlayer();
  String? _activeAudioUrl;

  void _updateChildLessonsState(VoidCallback callback) => setState(callback);

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadLessons();
    _loadStars();
    _loadEmergencyContacts();


  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _lessonAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChildAdaptationScope(
      childId: widget.childId,
      builder: (context) => AdaptiveWrapper(
        screenTitle: 'دروس ${widget.childName}',
        child: Scaffold(
          backgroundColor: widget.specialistS10
              ? const Color(0xFFF5F9FC) : null,
          appBar: widget.specialistS10 ? _s10AppBar() : buildChildLessonsAppBar(
            context: context,
            childName: widget.childName,
            stars: _stars,
            onOpenSettings: _isSpecialist ? _openSettings : null,
            onOpenProgress: _openProgress,
          ),
          body: RefreshIndicator(
            onRefresh: _refreshLessons,
            child: ValueListenableBuilder<AccessibilityProfile>(
              valueListenable: AccessibilityService.instance.profile,
              builder: (context, _, _) =>
                  widget.specialistS10 ? _s10Body() : _buildBody(),
            ),
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

    final displayedLessons = List<Map>.from(_lessons);
    if (AccessibilityService.instance.profile.value.routineStructure) {
      displayedLessons.sort((a, b) {
        final aId = int.tryParse('${a['id']}') ?? 0;
        final bId = int.tryParse('${b['id']}') ?? 0;
        final order = aId.compareTo(bId);
        return order != 0 ? order : '${a['title']}'.compareTo('${b['title']}');
      });
    }
    if (AccessibilityService.instance.profile.value.simpleIconsGrid &&
        displayedLessons.isNotEmpty) {
      return ListView(
        padding: EdgeInsets.all(AdaptiveHelper.spacing),
        children: [
          _catalogHeader(),
          SimpleIconsGrid(children: [for (final lesson in displayedLessons)
            _catalogCard(lesson),
          ]),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      itemCount: _lessons.length + (_lessons.isEmpty ? 2 : 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return _catalogHeader();
        }

        if (_lessons.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: AdaptiveHelper.spacing * 2),
            child: Center(
              child: Column(
                children: [
                  Icon(AppIcons.lesson,
                      size: 64, color: JisrColors.of(context).muted),
                  SizedBox(height: AdaptiveHelper.spacing),
                  AdaptiveText(
                    'لا توجد دروس مخصصة لهذا الطفل بعد',
                    textAlign: TextAlign.center,
                    color: JisrColors.of(context).muted,
                  ),
                ],
              ),
            ),
          );
        }

        final lessonIndex = i - 1;
        return _catalogCard(displayedLessons[lessonIndex]);
      },
    );
  }

  Widget _catalogHeader() => buildAdaptiveHeader(
    context: context, childId: widget.childId, childName: widget.childName,
    parentPhone: widget.parentPhone, specialistPhone: _specialistPhone,
    canMarkDone: _canMarkDone, timerCycle: _timerCycle, onOpenGames: _openGames,
    onTimerFinished: () => setState(() => _timerCycle++),
  );

  Widget _catalogCard(Map lesson) => buildLessonCard(
    context: context, lesson: lesson, doneLessonIds: _doneLessonIds,
    speakingLessonId: _speakingLessonId, savingLessonId: _savingLessonId,
    canMarkDone: _canMarkDone, onOpenLesson: _openLesson,
    onToggleSpeak: _toggleSpeak, onMarkDone: _markLessonDone,
  );

}
