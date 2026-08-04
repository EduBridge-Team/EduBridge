// شاشة تصفّح كل الدروس مع بحث وقراءة صوتية — مثل صفحة «تصفح الدروس» في الموقع
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../theme.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List _lessons = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  // القراءة الصوتية (accessibility)
  final FlutterTts _tts = FlutterTts();
  int? _speakingLessonId;

  @override
  void initState() {
    super.initState();
    _initTts();
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
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingLessonId = null);
    });
  }

  Future<void> _loadLessons() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/lessons');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _lessons = data['lessons'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب الدروس';
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

  // قراءة الدرس صوتياً أو إيقافها
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
      (lesson['title'] ?? '').toString(),
      (lesson['content'] ?? '').toString(),
    ].where((t) => t.isNotEmpty).join('. ');
    await _tts.speak(text);
  }

  // فلترة بالبحث على العنوان والمحتوى
  List get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _lessons;
    return _lessons.where((l) {
      final title = (l['title'] ?? '').toString();
      final content = (l['content'] ?? '').toString();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JisrAppBar(title: 'تصفح الدروس'),
      body: Column(
        children: [
          // حقل البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: TextField(
              style: const TextStyle(fontSize: 17),
              decoration: const InputDecoration(
                hintText: 'ابحث عن درس...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLessons,
              child: _buildBody(),
            ),
          ),
        ],
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
                label: const Text('إعادة المحاولة',
                    style: TextStyle(fontSize: 18)),
                onPressed: _loadLessons,
              ),
            ),
          ],
        ),
      );
    }

    final lessons = _filtered;
    if (lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.menu_book, size: 72, color: AppColors.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _lessons.isEmpty ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة لبحثك',
              style: const TextStyle(fontSize: 18, color: AppColors.muted),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: lessons.length,
      itemBuilder: (context, i) => _buildLessonCard(lessons[i]),
    );
  }

  Widget _buildLessonCard(Map lesson) {
    final isSpeaking = _speakingLessonId == lesson['id'];
    final content = (lesson['content'] ?? '').toString();

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
                    color: AppColors.tintGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.menu_book,
                      size: 28, color: AppColors.greenDeep),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (lesson['title'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
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
          ],
        ),
      ),
    );
  }
}
