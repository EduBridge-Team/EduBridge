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

  Future<void> _loadRole() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() {
      _canMarkDone = role == 'teacher' || role == 'specialist' || role == 'admin';
    });
  }

  Future<void> _loadStars() async {
    final stars = await RewardService.instance.getStars(widget.childId);
    if (!mounted) return;
    setState(() => _stars = stars);
  }

  Future<void> _loadLessons() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.authGet('/children/${widget.childId}/lessons'),
        ApiService.authGet('/progress/child/${widget.childId}'),
      ]);

      final lessonsRes = responses[0];
      final progressRes = responses[1];
      final lessonsData = jsonDecode(lessonsRes.body);

      if (lessonsRes.statusCode == 200) {
        _doneLessonIds.clear();
        if (progressRes.statusCode == 200) {
          final progress = jsonDecode(progressRes.body)['progress'] ?? [];
          for (final p in progress) {
            if (p['status'] == 'done' && p['lesson_id'] is int) {
              _doneLessonIds.add(p['lesson_id'] as int);
            }
          }
        }
        if (!mounted) return;
        setState(() {
          _lessons = lessonsData['lessons'] ?? [];
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = lessonsData['error'] ?? 'تعذّر جلب الدروس';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _markLessonDone(int lessonId) async {
    setState(() => _savingLessonId = lessonId);

    try {
      final res = await ApiService.authPost('/progress', {
        'child_id': widget.childId,
        'lesson_id': lessonId,
        'status': 'done',
      });

      if (!mounted) return;
      if (res.statusCode == 201) {
        setState(() => _doneLessonIds.add(lessonId));

        await RewardService.instance.addStar(widget.childId);
        await _loadStars();

        if (!mounted) return;

        final profile = AccessibilityService.instance.profile.value;
        if (profile.rewardSystem) {
          await RewardService.showReward(
            context,
            message: 'أحسنت! +نجمة',
            emoji: '🏆',
            stars: 1,
          );
        } else {
          await VisualCelebration.show(
            context,
            message: 'أكملت الدرس!',
            emoji: '🏆',
            childName: widget.childName,
            duration: const Duration(seconds: 3),
          );
        }

        if (mounted && _doneLessonIds.length % 3 == 0) {
          _suggestGames();
        }
      }
    } catch (e) {
      // Silent
    } finally {
      if (mounted) setState(() => _savingLessonId = null);
    }
  }

  void _suggestGames() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdaptiveHelper.cardRadius),
        ),
        title: Row(
          children: [
            Icon(AppIcons.game, color: AppColors.orange, size: 26),
            const SizedBox(width: 8),
            const AdaptiveText('وقت اللعب!', type: AdaptiveTextType.title),
          ],
        ),
        content: const AdaptiveText(
          'أكملت 3 دروس! هل تريد اللعب قليلاً؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AdaptiveButton(
                  label: 'لاحقاً',
                  style: AdaptiveButtonStyle.outlined,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: AdaptiveHelper.spacing / 2),
              Expanded(
                child: AdaptiveButton(
                  label: 'هيا!',
                  backgroundColor: AppColors.orange,
                  onPressed: () {
                    Navigator.pop(context);
                    _openGames();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSpeak(Map lesson) async {
    final rawId = lesson['id'];
    if (_speakingLessonId == rawId) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.stop();
    if (!mounted) return;
    setState(() => _speakingLessonId = rawId is int ? rawId : null);

    var text = [
      lesson['title'] ?? '',
      lesson['content'] ?? '',
    ].where((t) => t.toString().isNotEmpty).join('. ');

    if (text.trim().isEmpty) {
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    final profile = AccessibilityService.instance.profile.value;
    if (profile.verySimpleLanguage) {
      text = SimpleLanguageService.instance.simplify(text);
    }
    if (profile.shortSentences) {
      text = SimpleLanguageService.instance.shorten(text, maxWords: 10);
    }

    if (profile.slowSpeech) {
      await TtsService.instance.speakLineSlow(text);
    } else {
      await TtsService.instance.speakLine(text);
    }
    if (mounted) setState(() => _speakingLessonId = null);
  }

  Future<T?> _openOutsideChildScope<T>(Route<T> route) async {
    await AccessibilityService.instance.setActiveChild(null);
    if (!mounted) return null;

    final result = await Navigator.push<T>(context, route);

    if (mounted) {
      await AccessibilityService.instance.setActiveChild(
        widget.childId,
        disabilityTypeHint: widget.disabilityType,
      );
    }
    return result;
  }

  Future<void> _openGames() async {
    await _openOutsideChildScope(
      MaterialPageRoute(
        builder: (_) => EducationalGamesScreen(
          childName: widget.childName,
          age: widget.age,
        ),
      ),
    );
  }

  void _openSettings() async {
    await AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityType,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildAccessibilitySettingsScreen(
          childId: widget.childId,
          childName: widget.childName,
          disabilityTypeHint: widget.disabilityType,
          deactivateOnExit: false,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openProgress() async {
    await _openOutsideChildScope(
      MaterialPageRoute(
        builder: (_) => ChildProgressScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
    _loadLessons();
  }

  void _openLesson(Map lesson) {
    final profile = AccessibilityService.instance.profile.value;
    var title = (lesson['title'] ?? '').toString();
    var content = (lesson['content'] ?? '').toString();

    if (profile.verySimpleLanguage) {
      title = SimpleLanguageService.instance.simplify(title);
      content = SimpleLanguageService.instance.simplify(content);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildLessonDetailModal(
        context: context,
        title: title,
        content: content,
        lesson: lesson,
        activeAudioUrl: _activeAudioUrl,
        onToggleAudio: _toggleLessonAudio,
        onOpenAssistant: _openAssistantFromLesson,
        onOpenVideo: _openVideoFromLesson,
      ),
    );
  }

  Future<void> _toggleLessonAudio(String url) async {
    if (_activeAudioUrl == url) {
      await _lessonAudioPlayer.stop();
      if (mounted) setState(() => _activeAudioUrl = null);
      return;
    }

    await _lessonAudioPlayer.stop();
    await _lessonAudioPlayer.play(UrlSource(url));
    if (mounted) setState(() => _activeAudioUrl = url);
  }

  void _openAssistantFromLesson(String title, String content) {
    _openOutsideChildScope(
      MaterialPageRoute(
        builder: (_) => AssistantScreen(
          lessonContext: 'عنوان: $title\n$content',
        ),
      ),
    );
  }

  void _openVideoFromLesson({
    required String videoUrl,
    String? captionUrl,
    String? signLanguageUrl,
    String? audioDescription,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdaptiveVideoPlayer(
          videoUrl: videoUrl,
          captionUrl: captionUrl,
          signLanguageUrl: signLanguageUrl,
          audioDescription: audioDescription,
          title: title,
        ),
      ),
    );
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