// شاشة دروس الطفل — مع المؤقّت المتجدّد + الفاصل الذهني + الألعاب حسب العمر
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../utils/adaptive_theme.dart';
import '../widgets/accessibility/audio_timer.dart';
import '../widgets/accessibility/brain_break_overlay.dart';
import '../widgets/accessibility/emergency_button.dart';
import '../widgets/accessibility/profile_badge.dart';
import '../widgets/accessibility/step_by_step_lesson.dart';
import '../widgets/accessibility/visual_alert.dart';
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

  final FlutterTts _tts = FlutterTts();
  int? _speakingLessonId;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadRole();
    _loadLessons();

    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityType,
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingLessonId = null);
    });
  }

  Future<void> _loadRole() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() {
      _canMarkDone =
          role == 'teacher' || role == 'specialist' || role == 'admin';
    });
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
        setState(() {
          _lessons = lessonsData['lessons'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = lessonsData['error'] ?? 'تعذّر جلب الدروس';
          _loading = false;
        });
      }
    } catch (e) {
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
        await VisualCelebration.show(
          context,
          message: 'أكملت الدرس!',
          emoji: '🏆',
          childName: widget.childName,
          duration: const Duration(seconds: 3),
        );
        if (mounted && _doneLessonIds.length % 3 == 0) {
          _suggestGames();
        }
      } else {
        final data = jsonDecode(res.body);
        notifyUser(context, data['error'] ?? 'تعذّر تسجيل الإتمام',
            icon: Icons.error, color: Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      notifyUser(context, 'تعذّر الاتصال بالسيرفر',
          icon: Icons.wifi_off, color: Colors.red);
    } finally {
      if (mounted) setState(() => _savingLessonId = null);
    }
  }

  void _suggestGames() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎮 وقت اللعب!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: const Text('أكملت 3 دروس! هل تريد اللعب قليلاً؟',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        actions: [
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لاحقاً'))),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange),
                icon: const Icon(Icons.play_arrow),
                label: const Text('هيا!'),
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
          ]),
        ],
      ),
    );
  }

  Future<void> _toggleSpeak(Map lesson) async {
    final rawId = lesson['id'];
    if (_speakingLessonId == rawId) {
      await _tts.stop();
      setState(() => _speakingLessonId = null);
      return;
    }

    await _tts.stop();
    setState(() => _speakingLessonId = rawId is int ? rawId : null);
    final text = [
      lesson['title'] ?? '',
      lesson['content'] ?? '',
    ].where((t) => t.isNotEmpty).join('. ');

    final p = AccessibilityService.instance.profile.value;
    if (p.slowSpeech) {
      await TtsService.instance.speakLineSlow(text);
      if (mounted) setState(() => _speakingLessonId = null);
    } else {
      await _tts.speak(text);
    }
  }

  void _openLesson(Map lesson) {
    final p = AccessibilityService.instance.profile.value;
    if (p.stepByStepLessons) {
      _openStepByStep(lesson);
      return;
    }
    _showLessonDetail(lesson);
  }

  void _openStepByStep(Map lesson) {
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StepByStepLesson(
          lessonTitle: title,
          childName: widget.childName,
          steps: [
            LessonStep(
              title: 'مقدمة',
              content: 'سنتعلّم اليوم: $title',
              imageEmoji: '📚',
              realLifeExample: 'هذا الموضوع موجود في حياتنا اليومية.',
            ),
            if (content.isNotEmpty)
              LessonStep(
                title: 'المحتوى',
                content: content,
                imageEmoji: '📖',
                realLifeExample: 'جرّب أن تجد مثالاً مشابهاً في بيتك.',
              ),
            const LessonStep(
              title: 'التطبيق',
              content: 'هيا نطبّق ما تعلّمناه معاً!',
              imageEmoji: '✍️',
              realLifeExample: 'اطلب من والدتك مساعدتك في تمرين.',
            ),
            const LessonStep(
              title: 'أحسنت!',
              content: 'أكملت هذا الدرس. أنت رائع!',
              imageEmoji: '🌟',
            ),
          ],
        ),
      ),
    ).then((_) {
      final id = lesson['id'];
      if (_canMarkDone && mounted && id is int && id > 0) {
        _askToMarkDone(id);
      }
    });
  }

  void _askToMarkDone(int lessonId) {
    if (_doneLessonIds.contains(lessonId)) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 أكملت الدرس!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: const Text('هل تريد تسجيل إتمام الدرس؟',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () {
              Navigator.pop(context);
              _markLessonDone(lessonId);
            },
            child: const Text('نعم، سجّل'),
          ),
        ],
      ),
    );
  }

  void _showLessonDetail(Map lesson) {
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildDetailModal(title, content),
    );
  }

  Widget _buildDetailModal(String title, String content) {
    final p = AccessibilityService.instance.profile.value;
    final v = AdaptiveVisuals.fromProfile(p);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: v.surfaceColor,
        borderRadius: BorderRadius.circular(v.cardRadius),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: v.titleFontSize + 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            if (content.isNotEmpty)
              Text(content,
                  style: TextStyle(fontSize: v.bodyFontSize, height: 1.6)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: v.buttonHeight,
              child: OutlinedButton.icon(
                icon: Icon(Icons.auto_awesome, size: v.iconSize),
                label: Text('اسأل نور',
                    style: TextStyle(fontSize: v.bodyFontSize)),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AccessibilityService.instance.profile.value;
    final v = AdaptiveVisuals.fromProfile(p);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(color: v.accentColor),
        title: Text(
          'دروس ${widget.childName}',
          style: TextStyle(
            fontSize: v.titleFontSize - 2,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.accessibility_new, size: v.iconSize),
            tooltip: 'إعدادات ${widget.childName}',
            onPressed: () async {
              await AccessibilityService.instance.setActiveChild(
                widget.childId,
              );
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
            },
          ),
          IconButton(
            icon: Icon(Icons.insights, size: v.iconSize),
            tooltip: 'التقدّم',
            onPressed: () async {
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
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLessons,
        child: _buildBody(v),
      ),
    );
  }

  Widget _buildBody(AdaptiveVisuals v) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              height: v.buttonHeight,
              child: ElevatedButton.icon(
                icon: Icon(Icons.refresh, size: v.iconSize),
                label: Text('إعادة المحاولة',
                    style: TextStyle(fontSize: v.bodyFontSize)),
                onPressed: _loadLessons,
              ),
            ),
          ],
        ),
      );
    }

    final p = AccessibilityService.instance.profile.value;

    final lessonsToShow =
        _lessons.isEmpty ? _getSampleLessons(p.type) : _lessons;
    final showSampleBanner = _lessons.isEmpty;

    return ListView.builder(
      padding: EdgeInsets.all(v.spacing - 4),
      itemCount: lessonsToShow.length + (showSampleBanner ? 2 : 1),
      itemBuilder: (context, i) {
        if (i == 0) return _buildAdaptiveHeader(v);

        if (showSampleBanner && i == 1) {
          return Padding(
            padding: EdgeInsets.only(bottom: v.spacing),
            child: Container(
              padding: EdgeInsets.all(v.spacing - 4),
              decoration: BoxDecoration(
                color: v.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(v.cardRadius),
                border: Border.all(
                  color: v.accentColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: v.accentColor, size: v.iconSize),
                  SizedBox(width: v.spacing - 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📌 دروس تجريبية',
                          style: TextStyle(
                            fontSize: v.bodyFontSize,
                            fontWeight: FontWeight.bold,
                            color: v.accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'عندما تُضاف دروس حقيقية، ستظهر هنا تلقائياً',
                          style: TextStyle(
                            fontSize: v.bodyFontSize - 3,
                            color: v.accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final lessonIndex = i - (showSampleBanner ? 2 : 1);
        return _buildLessonCard(lessonsToShow[lessonIndex], v);
      },
    );
  }

  Widget _buildAdaptiveHeader(AdaptiveVisuals v) {
    final p = AccessibilityService.instance.profile.value;
    final items = <Widget>[];

    // قيمة آمنة للمؤقّت
    final timerMinutes =
        (p.timerRenewalMinutes > 0) ? p.timerRenewalMinutes : 5;

    // شارة البروفايل
    items.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: Alignment.center,
          child: const ProfileBadge(showFullLabel: true),
        ),
      ),
    );

    // زر الألعاب
    items.add(
      Padding(
        padding: EdgeInsets.only(bottom: v.spacing),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EducationalGamesScreen(
                childName: widget.childName,
                age: widget.age,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(v.cardRadius),
          child: Container(
            padding: EdgeInsets.all(v.spacing + 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [v.accentColor, v.accentColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(v.cardRadius),
            ),
            child: Row(
              children: [
                Text(
                  p.type == DisabilityType.blind ? '🎧' : '🎮',
                  style: TextStyle(fontSize: v.iconSize + 10),
                ),
                SizedBox(width: v.spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.type == DisabilityType.blind
                            ? 'ألعاب سمعية'
                            : 'الألعاب التعليمية',
                        style: TextStyle(
                          fontSize: v.bodyFontSize + 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.type == DisabilityType.blind
                            ? 'ألعاب بأذنيك 🎧'
                            : 'العب وتعلّم — مناسبة لعمرك 🎉',
                        style: TextStyle(
                          fontSize: v.bodyFontSize - 3,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left,
                    color: Colors.white, size: 32),
              ],
            ),
          ),
        ),
      ),
    );

    // المؤقّت
    if (p.visualTimerEnabled && !p.noTimers) {
      items.add(
        Padding(
          padding: EdgeInsets.only(bottom: v.spacing),
          child: p.type == DisabilityType.blind
              ? AudioTimer(
                  key: ValueKey('audio_timer_cycle_$_timerCycle'),
                  total: Duration(minutes: timerMinutes),
                  childName: widget.childName,
                  onFinished: () async {
                    TtsService.instance.speakLine(
                      'انتهى الوقت! وقت الراحة $timerMinutes دقائق',
                    );
                    if (mounted) {
                      await BrainBreakDialog.show(context);
                      if (mounted) {
                        setState(() => _timerCycle++);
                      }
                    }
                  },
                )
              : Column(
                  children: [
                    if (_timerCycle > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: v.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: v.accentColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh,
                                  size: 16, color: v.accentColor),
                              const SizedBox(width: 6),
                              Text(
                                '🔄 الدورة ${_timerCycle + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: v.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Center(
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
                          if (mounted) {
                            setState(() => _timerCycle++);
                          }
                        },
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    // الخط الزمني
    if (p.predictableTimeline) {
      items.add(
        Padding(
          padding: EdgeInsets.only(bottom: v.spacing),
          child: VisualTimeline(
            title: 'خطوات الدرس',
            steps: [
              const TimelineStep(
                  emoji: '📖', label: 'اقرأ العنوان', done: true),
              TimelineStep(
                  emoji: '🎧',
                  label: 'استمع للشرح',
                  current: !_canMarkDone),
              TimelineStep(
                  emoji: '✍️',
                  label: 'حلّ التمرين',
                  done: _canMarkDone),
              const TimelineStep(emoji: '⭐', label: 'احصل على نجمة'),
            ],
          ),
        ),
      );
    }

    // زر الطوارئ
    if (p.emergencyButton) {
      items.add(EmergencyButton(
        childName: widget.childName,
        parentPhone: widget.parentPhone,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  Widget _buildLessonCard(Map lesson, AdaptiveVisuals v) {
    final p = AccessibilityService.instance.profile.value;

    final rawId = lesson['id'];
    final int lessonId = (rawId is int) ? rawId : -999;

    final isDone = _doneLessonIds.contains(lessonId);
    final isSpeaking = _speakingLessonId == lessonId;
    final isSaving = _savingLessonId == lessonId;
    final isSample = lessonId < 0;

    return Container(
      margin: EdgeInsets.only(bottom: v.spacing - 4),
      decoration: BoxDecoration(
        color: v.surfaceColor,
        borderRadius: BorderRadius.circular(v.cardRadius),
        border: Border.all(
          color: isDone ? v.accentColor : v.accentColor.withValues(alpha: 0.2),
          width: isDone ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: v.accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isSample ? null : () => _openLesson(lesson),
        borderRadius: BorderRadius.circular(v.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(v.spacing - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: v.iconSize + 18,
                    height: v.iconSize + 18,
                    decoration: BoxDecoration(
                      color: isDone
                          ? v.accentColor.withValues(alpha: 0.15)
                          : v.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(v.cardRadius - 8),
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle : Icons.menu_book,
                      size: v.iconSize,
                      color: v.accentColor,
                    ),
                  ),
                  SizedBox(width: v.spacing - 2),
                  Expanded(
                    child: Text(
                      (lesson['title'] ?? '').toString(),
                      style: TextStyle(
                        fontSize: v.bodyFontSize + 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (p.stepByStepLessons)
                    Icon(Icons.list_alt,
                        color: v.accentColor, size: v.iconSize)
                  else if (!isSample)
                    Icon(Icons.chevron_left,
                        color: v.accentColor, size: v.iconSize),
                ],
              ),
              if (lesson['content'] != null &&
                  !p.stepByStepLessons) ...[
                SizedBox(height: v.spacing - 6),
                Text(
                  (lesson['content'] ?? '').toString(),
                  style: TextStyle(fontSize: v.bodyFontSize, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: v.spacing - 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: v.buttonHeight - 8,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: v.accentColor,
                          side: BorderSide(color: v.accentColor),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(v.cardRadius - 10),
                          ),
                        ),
                        icon: Icon(
                          isSpeaking ? Icons.stop_circle : Icons.volume_up,
                          size: v.iconSize - 4,
                        ),
                        label: Text(isSpeaking ? 'إيقاف' : 'استمع',
                            style: TextStyle(fontSize: v.bodyFontSize - 2)),
                        onPressed: () => _toggleSpeak(lesson),
                      ),
                    ),
                  ),
                  if (_canMarkDone && !isSample) ...[
                    SizedBox(width: v.spacing - 6),
                    Expanded(
                      child: SizedBox(
                        height: v.buttonHeight - 8,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDone ? AppColors.greenDeep : v.accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(v.cardRadius - 10),
                            ),
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(
                                  isDone ? Icons.check_circle : Icons.check,
                                  size: v.iconSize - 4),
                          label: Text(isDone ? 'مكتمل' : 'تمّ',
                              style: TextStyle(fontSize: v.bodyFontSize - 2)),
                          onPressed: (isDone || isSaving)
                              ? null
                              : () => _markLessonDone(lessonId),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleLessons(DisabilityType type) {
    switch (type) {
      case DisabilityType.adhd:
        return [
          {'id': -1, 'title': '⚡ الأرقام السريعة', 'content': 'لعبة سريعة لتعلّم الأرقام من 1 إلى 10.'},
          {'id': -2, 'title': '🎨 ألوان حولنا', 'content': 'تعرّف على الألوان الأساسية.'},
          {'id': -3, 'title': '🏃 حروف وحركة', 'content': 'اقفز مع كل حرف.'},
        ];
      case DisabilityType.autismMild:
      case DisabilityType.autismSevere:
        return [
          {'id': -1, 'title': '🌅 الروتين اليومي', 'content': 'خطوات الصباح.'},
          {'id': -2, 'title': '🔢 العدّ من 1 إلى 5', 'content': 'واحد، اثنان...'},
          {'id': -3, 'title': '🎨 الألوان الهادئة', 'content': 'اللون الأزرق.'},
        ];
      case DisabilityType.downSyndrome:
        return [
          {'id': -1, 'title': '🍎 الفواكه', 'content': 'هذه تفاحة 🍎.'},
          {'id': -2, 'title': '🐶 الحيوانات', 'content': 'هذا كلب 🐶.'},
          {'id': -3, 'title': '🌞 الطقس', 'content': 'الشمس مشرقة ☀️.'},
        ];
      case DisabilityType.blind:
        return [
          {'id': -1, 'title': '🎵 أصوات الحيوانات', 'content': 'استمع للأصوات.'},
          {'id': -2, 'title': '✋ الملمس والأشكال', 'content': 'المربع والمستطيل.'},
        ];
      case DisabilityType.deaf:
        return [
          {'id': -1, 'title': '🤟 حروف الإشارة', 'content': 'إشارة الألف 👍.'},
          {'id': -2, 'title': '📖 القراءة البصرية', 'content': 'بيت 🏠، شمس ☀️.'},
        ];
      case DisabilityType.stuttering:
        return [
          {'id': -1, 'title': '🐢 القراءة البطيئة', 'content': 'اقرأ ببطء.'},
          {'id': -2, 'title': '🎵 الإيقاع والكلام', 'content': 'انقر مع الكلمات.'},
        ];
      case DisabilityType.speechDisorders:
        return [
          {'id': -1, 'title': '👄 تمارين النطق', 'content': 'قل: را را را.'},
          {'id': -2, 'title': '🎤 أصوات الحروف', 'content': 'ب مثل بيضة 🥚.'},
        ];
      case DisabilityType.mildIntellectual:
        return [
          {'id': -1, 'title': '🧼 غسل اليدين', 'content': 'افتح الماء.'},
          {'id': -2, 'title': '🍽️ آداب الطعام', 'content': 'اجلس على الكرسي.'},
          {'id': -3, 'title': '👕 ترتيب الملابس', 'content': 'افتح الخزانة.'},
        ];
      case DisabilityType.colorBlindness:
        return [
          {'id': -1, 'title': '🔴 الألوان بالرموز', 'content': 'أحمر ▲ - أزرق ■.'},
          {'id': -2, 'title': '🎨 الأنماط والتصنيف', 'content': 'صنّف حسب الشكل.'},
        ];
      case DisabilityType.epilepsy:
        return [
          {'id': -1, 'title': '🧘 التنفّس الهادئ', 'content': 'خذ نفساً عميقاً.'},
          {'id': -2, 'title': '📖 قصة هادئة', 'content': 'أرنب صغير 🐰.'},
        ];
      default:
        return [
          {'id': -1, 'title': '📖 درس تجريبي', 'content': 'درس لعرض المحتوى.'},
          {'id': -2, 'title': '🎯 درس قابل للتخصيص', 'content': 'خصّصه كما تريد.'},
        ];
    }
  }
}