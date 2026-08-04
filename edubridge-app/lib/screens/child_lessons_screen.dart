// شاشة دروس الطفل (المناسبة لنوع إعاقته)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'child_progress_screen.dart';

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
  // الدرس الذي يجري حفظ إتمامه الآن (لتعطيل زره أثناء الطلب)
  int? _savingLessonId;
  // ولي الأمر يعرض فقط — لا يسجّل إتماماً
  bool _canMarkDone = false;

  // القراءة الصوتية للدروس (accessibility)
  final FlutterTts _tts = FlutterTts();
  int? _speakingLessonId;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadRole();
    _loadLessons();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45); // أبطأ قليلاً ليناسب الأطفال
    // عند انتهاء القراءة نرجّع أيقونة السماعة لوضعها الطبيعي
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
      // نجلب الدروس وسجلّ التقدّم معاً لمعرفة الدروس المكتملة
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

  // تسجيل إتمام الدرس — POST /api/progress
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أحسنت! تم تسجيل إتمام الدرس 🎉',
                style: TextStyle(fontSize: 16)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'تعذّر تسجيل الإتمام',
                style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('تعذّر الاتصال بالسيرفر', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingLessonId = null);
    }
  }

  // قراءة الدرس صوتياً — أو إيقاف القراءة إذا كانت شغّالة
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
          // زر التقدّم — يفتح شاشة ملخّص وتفاصيل التقدّم
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
              // نحدّث القائمة بعد الرجوع (قد يتغيّر التقدّم)
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
                label:
                    const Text('إعادة المحاولة', style: TextStyle(fontSize: 18)),
                onPressed: _loadLessons,
              ),
            ),
          ],
        ),
      );
    }
    if (_lessons.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.menu_book, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Center(
            child:
                Text('لا توجد دروس مناسبة بعد', style: TextStyle(fontSize: 18)),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _lessons.length,
      itemBuilder: (context, i) => _buildLessonCard(_lessons[i]),
    );
  }

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
                // أيقونة الدرس داخل مربّع ملوّن ناعم
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
                // زر الاستماع — يقرأ الدرس صوتياً للطفل
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
                // زر «تمّ» — للمعلّم/المختص/الأدمن فقط
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
                            : Icon(isDone ? Icons.check_circle : Icons.check,
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
          ],
        ),
      ),
    );
  }
}
