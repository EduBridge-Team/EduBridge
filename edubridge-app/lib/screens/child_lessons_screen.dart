// screens/child_lessons_screen.dart
// دروس الطفل — مع كل ميزات التكييف + دعم الفيديو والصوت
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../services/simple_language_service.dart';
import '../services/reward_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/adaptive_button.dart';
import '../widgets/accessibility/adaptive_card.dart';
import '../widgets/accessibility/adaptive_text.dart';
import '../widgets/accessibility/adaptive_video_player.dart';
import '../widgets/accessibility/adaptive_wrapper.dart';
import '../widgets/accessibility/audio_timer.dart';
import '../widgets/accessibility/brain_break_overlay.dart';
import '../widgets/accessibility/emergency_button.dart';
import '../widgets/accessibility/visual_celebration.dart';
import '../widgets/accessibility/visual_timeline.dart';
import '../widgets/accessibility/visual_timer.dart';
import 'child_accessibility_settings_screen.dart';
import 'child_progress_screen.dart';
import 'educational_games_screen.dart';
import 'assistant_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadLessons();
    _loadStars();

    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityType,
    );
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    AccessibilityService.instance.setActiveChild(null);
    super.dispose();
  }

  Future<void> _loadRole() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() {
      _canMarkDone =
          role == 'teacher' || role == 'specialist' || role == 'admin';
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
            message: 'أحسنت! +⭐',
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
      // ...
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
        title: AdaptiveText(
          '🎮 وقت اللعب!',
          type: AdaptiveTextType.title,
          textAlign: TextAlign.center,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EducationalGamesScreen(
                          childName: widget.childName,
                          age: widget.age,
                        ),
                      ),
                    );
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

  void _openGames() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EducationalGamesScreen(
          childName: widget.childName,
          age: widget.age,
        ),
      ),
    );
  }

  void _openSettings() async {
    await AccessibilityService.instance.setActiveChild(widget.childId);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildAccessibilitySettingsScreen(
          childId: widget.childId,
          childName: widget.childName,
          disabilityTypeHint: widget.disabilityType,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openProgress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildProgressScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
    _loadLessons();
  }

  // ═══════════════════════════════════════════════════════════
  //  عرض الدرس — فيديو إذا وُجد، وإلا نص
  // ═══════════════════════════════════════════════════════════
  void _openLesson(Map lesson) {
    final videoUrl = lesson['video_url']?.toString();
    final captionUrl = lesson['caption_url']?.toString();
    final signLanguageUrl = lesson['sign_language_url']?.toString();
    final audioDescription = lesson['audio_description']?.toString();
    final title = (lesson['title'] ?? '').toString();

    // ✅ إذا وُجد فيديو → افتح مشغّل الفيديو المتكيّف
    if (videoUrl != null && videoUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdaptiveVideoPlayer(
            videoUrl: videoUrl,
            captionUrl:
                captionUrl != null && captionUrl.isNotEmpty ? captionUrl : null,
            signLanguageUrl:
                signLanguageUrl != null && signLanguageUrl.isNotEmpty
                    ? signLanguageUrl
                    : null,
            audioDescription:
                audioDescription != null && audioDescription.isNotEmpty
                    ? audioDescription
                    : null,
            title: title,
          ),
        ),
      );
      return;
    }

    // ⚠️ إذا وُجد صوت فقط
    final audioUrl = lesson['audio_url']?.toString();
    if (audioUrl != null && audioUrl.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 يحتوي هذا الدرس على تسجيل صوتي'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // ─── عرض النص ───
    final profile = AccessibilityService.instance.profile.value;
    var simpleTitle = title;
    var content = (lesson['content'] ?? '').toString();

    if (profile.verySimpleLanguage) {
      simpleTitle = SimpleLanguageService.instance.simplify(simpleTitle);
      content = SimpleLanguageService.instance.simplify(content);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildDetailModal(simpleTitle, content, lesson),
    );
  }

  Widget _buildDetailModal(String title, String content, Map lesson) {
    return Container(
      margin: EdgeInsets.all(AdaptiveHelper.spacing),
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      decoration: BoxDecoration(
        color: AdaptiveHelper.cardColor(context),
        borderRadius: BorderRadius.circular(AdaptiveHelper.cardRadius),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AdaptiveText(
                    title,
                    type: AdaptiveTextType.title,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            if (content.isNotEmpty)
              AdaptiveText(content, type: AdaptiveTextType.body),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: 'اسأل نور',
              icon: Icons.auto_awesome,
              style: AdaptiveButtonStyle.outlined,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssistantScreen(
                      lessonContext: 'عنوان: $title\n$content',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  واجهة المستخدم
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper(
      screenTitle: 'دروس ${widget.childName}',
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
          ),
          // ✅ إصلاح: Text بدل Row + ellipsis + centerTitle false
          //    يحل مشكلة ضغط العنوان مع الأسماء الطويلة والإعاقات الحركية
          title: Text(
            'دروس ${widget.childName}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          centerTitle: false,
          actions: [
            // ⭐ النجوم — أصغر لتفادي الضغط
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 3),
                  Text(
                    '$_stars',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.accessibility_new, color: Colors.white),
              tooltip: 'إعدادات التكييف',
              onPressed: _openSettings,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              icon: const Icon(Icons.insights, color: Colors.white),
              tooltip: 'التقدّم',
              onPressed: _openProgress,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadLessons,
          child: _buildBody(),
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
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveText(
                _error!,
                textAlign: TextAlign.center,
                color: Colors.red,
              ),
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveButton(
                label: 'إعادة المحاولة',
                icon: Icons.refresh,
                onPressed: _loadLessons,
              ),
            ],
          ),
        ),
      );
    }

    final profile = AccessibilityService.instance.profile.value;
    final lessonsToShow =
        _lessons.isEmpty ? _getSampleLessons(profile.type) : _lessons;
    final showSampleBanner = _lessons.isEmpty;

    return ListView.builder(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      itemCount: lessonsToShow.length + (showSampleBanner ? 2 : 1),
      itemBuilder: (context, i) {
        if (i == 0) return _buildAdaptiveHeader();

        if (showSampleBanner && i == 1) {
          return _buildSampleBanner();
        }

        final lessonIndex = i - (showSampleBanner ? 2 : 1);
        return _buildLessonCard(lessonsToShow[lessonIndex]);
      },
    );
  }

  Widget _buildAdaptiveHeader() {
    final profile = AccessibilityService.instance.profile.value;
    final items = <Widget>[];

    items.add(
      Padding(
        padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
        child: AdaptiveCard(
          onTap: _openGames,
          backgroundColor: AdaptiveHelper.accentColor(context),
          child: Row(
            children: [
              Text(
                profile.type == DisabilityType.blind ? '🎧' : '🎮',
                style: TextStyle(fontSize: AdaptiveHelper.iconSize + 10),
              ),
              SizedBox(width: AdaptiveHelper.spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      profile.type == DisabilityType.blind
                          ? 'ألعاب سمعية'
                          : 'الألعاب التعليمية',
                      type: AdaptiveTextType.subtitle,
                      color: Colors.white,
                    ),
                    SizedBox(height: AdaptiveHelper.spacing / 4),
                    AdaptiveText(
                      'العب وتعلّم 🎉',
                      type: AdaptiveTextType.caption,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );

    if (profile.visualTimerEnabled && !profile.noTimers) {
      final timerMinutes =
          (profile.timerRenewalMinutes > 0) ? profile.timerRenewalMinutes : 5;
      items.add(
        Padding(
          padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
          child: profile.type == DisabilityType.blind
              ? AudioTimer(
                  key: ValueKey('audio_timer_cycle_$_timerCycle'),
                  total: Duration(minutes: timerMinutes),
                  childName: widget.childName,
                  onFinished: () async {
                    TtsService.instance.speakLine('انتهى الوقت! وقت الراحة');
                    if (mounted) {
                      await BrainBreakDialog.show(context);
                      if (mounted) setState(() => _timerCycle++);
                    }
                  },
                )
              : Center(
                  child: VisualTimer(
                    key: ValueKey('timer_cycle_$_timerCycle'),
                    total: Duration(minutes: timerMinutes),
                    label: 'وقت القراءة المتبقي',
                    showControls: true,
                    onFinished: () async {
                      await VisualCelebration.show(
                        context,
                        message: 'أحسنت! انتهت $timerMinutes دقائق',
                        emoji: '⏰',
                        childName: widget.childName,
                        duration: const Duration(seconds: 2),
                      );
                      if (mounted) {
                        await BrainBreakDialog.show(context);
                      }
                      if (mounted) setState(() => _timerCycle++);
                    },
                  ),
                ),
        ),
      );
    }

    if (profile.predictableTimeline) {
      items.add(
        Padding(
          padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
          child: VisualTimeline(
            title: 'خطوات الدرس',
            steps: [
              const TimelineStep(emoji: '📖', label: 'اقرأ العنوان', done: true),
              TimelineStep(
                  emoji: '🎧',
                  label: 'استمع للشرح',
                  current: !_canMarkDone),
              TimelineStep(
                  emoji: '✍️', label: 'حلّ التمرين', done: _canMarkDone),
              const TimelineStep(emoji: '⭐', label: 'احصل على نجمة'),
            ],
          ),
        ),
      );
    }

    if (profile.emergencyButton) {
      items.add(
        EmergencyButton(
          childName: widget.childName,
          parentPhone: widget.parentPhone,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  Widget _buildSampleBanner() {
    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 28),
            SizedBox(width: AdaptiveHelper.spacing / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdaptiveText(
                    '📌 دروس تجريبية',
                    type: AdaptiveTextType.body,
                    fontWeight: FontWeight.bold,
                  ),
                  AdaptiveText(
                    'عندما تُضاف دروس حقيقية، ستظهر هنا',
                    type: AdaptiveTextType.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map lesson) {
    final rawId = lesson['id'];
    final int lessonId = (rawId is int) ? rawId : -999;

    final isDone = _doneLessonIds.contains(lessonId);
    final isSpeaking = _speakingLessonId == lessonId;
    final isSaving = _savingLessonId == lessonId;
    final isSample = lessonId < 0;

    final videoUrl = lesson['video_url']?.toString();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasAudio = (lesson['audio_url']?.toString().isNotEmpty ?? false);

    final profile = AccessibilityService.instance.profile.value;
    var title = (lesson['title'] ?? '').toString();
    var content = (lesson['content'] ?? '').toString();

    if (profile.verySimpleLanguage) {
      title = SimpleLanguageService.instance.simplify(title);
      content = SimpleLanguageService.instance.simplify(content);
    }
    if (profile.shortSentences) {
      content = SimpleLanguageService.instance.shorten(content, maxWords: 10);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        onTap: isSample ? null : () => _openLesson(lesson),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AdaptiveHelper.iconSize + 20,
                  height: AdaptiveHelper.iconSize + 20,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.green.withValues(alpha: 0.15)
                        : AdaptiveHelper.accentColor(context)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AdaptiveHelper.cardRadius - 8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isDone
                        ? Icons.check_circle
                        : hasVideo
                            ? Icons.play_circle_fill
                            : hasAudio
                                ? Icons.volume_up
                                : Icons.menu_book,
                    size: AdaptiveHelper.iconSize,
                    color: isDone
                        ? AppColors.green
                        : AdaptiveHelper.accentColor(context),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveText(
                    title,
                    type: AdaptiveTextType.subtitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasVideo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.pink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_library,
                            size: 14, color: AppColors.pink),
                        SizedBox(width: 3),
                        Text(
                          'فيديو',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pink,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (hasAudio)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.audiotrack,
                            size: 14, color: AppColors.green),
                        SizedBox(width: 3),
                        Text(
                          'صوت',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isDone)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle,
                        color: AppColors.green, size: 28),
                  ),
              ],
            ),

            if (content.isNotEmpty) ...[
              SizedBox(height: AdaptiveHelper.spacing / 2),
              AdaptiveText(
                content,
                type: AdaptiveTextType.body,
                maxLines: 3,
              ),
            ],

            SizedBox(height: AdaptiveHelper.spacing),

            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: isSpeaking ? 'إيقاف' : 'استمع',
                    icon: isSpeaking ? Icons.stop_circle : Icons.volume_up,
                    style: AdaptiveButtonStyle.outlined,
                    fullWidth: true,
                    onPressed: () => _toggleSpeak(lesson),
                  ),
                ),
                if (_canMarkDone && !isSample) ...[
                  SizedBox(width: AdaptiveHelper.spacing / 2),
                  Expanded(
                    child: AdaptiveButton(
                      label: isDone ? 'مكتمل' : 'تمّ',
                      icon: isDone ? Icons.check_circle : Icons.check,
                      backgroundColor:
                          isDone ? AppColors.greenDeep : AppColors.green,
                      fullWidth: true,
                      onPressed: (isDone || isSaving)
                          ? null
                          : () => _markLessonDone(lessonId),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleLessons(DisabilityType type) {
    switch (type) {
      case DisabilityType.downSyndrome:
        return [
          {
            'id': -1,
            'title': '🍎 الفواكه',
            'content': 'هذه تفاحة. التفاحة حمراء. أكل التفاحة مفيد!'
          },
          {
            'id': -2,
            'title': '🐶 الحيوانات',
            'content': 'هذا كلب. الكلب يقول: هَو هَو.'
          },
          {
            'id': -3,
            'title': '🌞 الطقس',
            'content': 'الشمس مشرقة. نلبس ملابس خفيفة.'
          },
        ];
      case DisabilityType.blind:
        return [
          {
            'id': -1,
            'title': '🎵 أصوات الحيوانات',
            'content': 'الكلب يعوي: هَو هَو. القطة تموء: مياو.'
          },
          {
            'id': -2,
            'title': '✋ الملمس والأشكال',
            'content': 'المستطيل له 4 أضلاع. المربع كل أضلاعه متساوية.'
          },
        ];
      case DisabilityType.deaf:
        return [
          {
            'id': -1,
            'title': '🤟 حروف الإشارة',
            'content': 'إشارة الألف: ارفع إبهامك للأعلى 👍'
          },
          {
            'id': -2,
            'title': '📖 القراءة البصرية',
            'content': 'انظر للكلمات: بيت 🏠، شمس ☀️'
          },
        ];
      default:
        return [
          {
            'id': -1,
            'title': '📖 درس تجريبي',
            'content': 'هذا درس تجريبي.'
          },
        ];
    }
  }
}