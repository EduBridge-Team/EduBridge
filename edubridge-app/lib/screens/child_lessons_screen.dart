// شاشة دروس الطفل — مع كل الميزات التكيّفية
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/accessibility/audio_timer.dart';
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

  const ChildLessonsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildLessonsScreen> createState() => _ChildLessonsScreenState();
}

class _ChildLessonsScreenState extends State<ChildLessonsScreen> {
  List _lessons = [];
  bool _loading = true;
  String? _error;

  // الدروس المكتملة (من سجلّ التقدّم) لعرض علامة ✓
  final Set<int> _doneLessonIds = {};
  // الدرس الذي يجري حفظ إتمامه الآن
  int? _savingLessonId;
  // ولي الأمر يعرض فقط — لا يسجّل إتماماً
  bool _canMarkDone = false;

  // القراءة الصوتية للدروس
  final FlutterTts _tts = FlutterTts();
  int? _speakingLessonId;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadRole();
    _loadLessons();

    // ✅ نضمن أن بروفايل هذا الطفل نشط أثناء عرض الشاشة
    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: null,
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
            if (p['status'] == 'done' && p['lesson_id'] != null) {
              _doneLessonIds.add(p['lesson_id']);
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

  // تسجيل إتمام الدرس
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

        // 🎉 احتفال متكيّف مع كل الحالات
        await VisualCelebration.show(
          context,
          message: 'أكملت الدرس!',
          emoji: '🏆',
          childName: widget.childName,
          duration: const Duration(seconds: 3),
        );

        // 🎮 دعوة للألعاب بعد كل 3 دروس
        if (mounted && _doneLessonIds.length % 3 == 0) {
          _suggestGames();
        }
      } else {
        final data = jsonDecode(res.body);
        notifyUser(
          context,
          data['error'] ?? 'تعذّر تسجيل الإتمام',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      notifyUser(
        context,
        'تعذّر الاتصال بالسيرفر',
        icon: Icons.wifi_off,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _savingLessonId = null);
    }
  }

  // دعوة للألعاب بعد كل 3 دروس
  void _suggestGames() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🎮 وقت اللعب!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'أكملت 3 دروس! هل تريد اللعب قليلاً؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('لاحقاً'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('هيا!'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EducationalGamesScreen(
                          childName: widget.childName,
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

  // قراءة الدرس صوتياً
  Future<void> _toggleSpeak(Map lesson) async {
    final lessonId = lesson['id'];
    if (_speakingLessonId == lessonId) {
      await _tts.stop();
      setState(() => _speakingLessonId = null);
      return;
    }

    await _tts.stop();
    setState(() => _speakingLessonId = lessonId);
    final text = [
      lesson['title'] ?? '',
      lesson['content'] ?? '',
    ].where((t) => t.isNotEmpty).join('. ');
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(
        title: 'دروس ${widget.childName}',
        actions: [
          // زر إعدادات هذا الطفل
          IconButton(
            icon: const Icon(Icons.accessibility_new, size: 28),
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
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          // زر التقدّم
          IconButton(
            icon: const Icon(Icons.insights, size: 28),
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
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  //  ✅ معدّلة: يعرض الرأس التكيّفي دائماً حتى لو لا توجد دروس
  // ============================================================
  Widget _buildBody() {
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
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 28),
                label: const Text('إعادة المحاولة',
                    style: TextStyle(fontSize: 18)),
                onPressed: _loadLessons,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ حتى لو لا توجد دروس، نُظهر الرأس التكيّفي (زر الألعاب + المؤقّت)
    if (_lessons.isEmpty) {
      final c = JisrColors.of(context);
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildAdaptiveHeader(), // ← 🎮 زر الألعاب يظهر دائماً
          const SizedBox(height: 40),
          Icon(Icons.menu_book, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد دروس مناسبة بعد',
              style: TextStyle(
                fontSize: 18,
                color: c.muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'يمكنك اللعب بالألعاب التعليمية في الأعلى 🎮',
              style: TextStyle(
                fontSize: 14,
                color: c.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _lessons.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildAdaptiveHeader();
        return _buildLessonCard(_lessons[i - 1]);
      },
    );
  }

  // ============================================================
  //  الرأس التكيّفي: زر الألعاب + المؤقّت + الخط الزمني
  // ============================================================
  Widget _buildAdaptiveHeader() {
    final p = AccessibilityService.instance.profile.value;
    final isBlind = p.type == DisabilityType.blind;
    final items = <Widget>[];

    // 🎮 زر الألعاب — دائماً مرئي
    items.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EducationalGamesScreen(
                childName: widget.childName,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orange, AppColors.yellow],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  isBlind ? '🎧' : '🎮',
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBlind ? 'ألعاب سمعية' : 'الألعاب التعليمية',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBlind
                            ? 'ألعاب يمكنك لعبها بأذنيك 🎧'
                            : 'العب وتعلّم! 3 ألعاب ممتعة 🎉',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
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

    // 🕐 المؤقّت — بصري للأغلبية، سمعي للأعمى
    if (p.visualTimerEnabled) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: isBlind
              ? AudioTimer(
                  total: const Duration(minutes: 5),
                  childName: widget.childName,
                  onFinished: () {
                    TtsService.instance.speakLine('انتهى الوقت! أحسنت');
                  },
                )
              : Center(
                  child: VisualTimer(
                    total: const Duration(minutes: 5),
                    label: 'وقت القراءة المتبقي',
                    showControls: true,
                    onFinished: () {
                      VisualCelebration.show(
                        context,
                        message: 'أحسنت! انتهى الوقت',
                        emoji: '⏰',
                        childName: widget.childName,
                      );
                    },
                  ),
                ),
        ),
      );
    }

    // 📋 الخط الزمني
    if (p.predictableTimeline) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  // ============================================================
  //  بطاقة درس واحدة
  // ============================================================
  Widget _buildLessonCard(Map lesson) {
    final c = JisrColors.of(context);
    final lessonId = lesson['id'];
    final isDone = _doneLessonIds.contains(lessonId);
    final isSpeaking = _speakingLessonId == lessonId;
    final isSaving = _savingLessonId == lessonId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDone ? c.tintGreen : c.tintTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle : Icons.menu_book,
                    size: 28,
                    color: isDone
                        ? c.success
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lesson['title'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.heading,
                    ),
                  ),
                ),
              ],
            ),
            if (lesson['content'] != null) ...[
              const SizedBox(height: 8),
              Text(
                lesson['content'],
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // زر الاستماع
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        isSpeaking ? Icons.stop_circle : Icons.volume_up,
                        size: 28,
                      ),
                      label: Text(
                        isSpeaking ? 'إيقاف' : 'استمع',
                        style: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () => _toggleSpeak(lesson),
                    ),
                  ),
                ),
                // زر «تمّ» للمعلّم/المختص/الأدمن
                if (_canMarkDone) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(
                                isDone ? Icons.check_circle : Icons.check,
                                size: 28),
                        label: Text(
                          isDone ? 'مكتمل' : 'تمّ',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDone ? AppColors.greenDeep : AppColors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: (isDone || isSaving)
                            ? null
                            : () => _markLessonDone(lessonId),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 24),
                label: const Text('اسأل نور عن الدرس'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssistantScreen(
                      lessonContext: [
                        'عنوان الدرس: ${lesson['title'] ?? ''}',
                        if (lesson['content'] != null)
                          'محتوى الدرس: ${lesson['content']}',
                      ].join('\n'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}