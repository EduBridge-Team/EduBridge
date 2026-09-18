// شاشة تصفّح كل الدروس مع بحث وقراءة صوتية
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/speakable.dart';
import 'assistant_screen.dart';

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

  // ✅ إصلاح: نستخدم TtsService بدل FlutterTts مباشر
  int? _speakingLessonId;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
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
        if (!mounted) return;
        setState(() {
          _lessons = data['lessons'] ?? [];
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب الدروس';
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

  // ✅ إصلاح: استخدام TtsService.instance بدل FlutterTts
  Future<void> _toggleSpeak(Map lesson) async {
    final lessonId = lesson['id'];
    if (_speakingLessonId == lessonId) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.stop();
    if (!mounted) return;
    setState(() => _speakingLessonId = lessonId is int ? lessonId : null);

    final text = [
      (lesson['title'] ?? '').toString(),
      (lesson['content'] ?? '').toString(),
    ].where((t) => t.isNotEmpty).join('. ');

    if (text.trim().isEmpty) {
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.speakLine(text);
    if (mounted) setState(() => _speakingLessonId = null);
  }

  String _buildLessonSpeech(Map lesson) {
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();

    final parts = <String>[
      'درس: $title',
      if (content.isNotEmpty) content,
      'اضغط لسماع الدرس',
    ];

    return parts.join('، ');
  }

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
          Icon(Icons.menu_book, size: 72, color: JisrColors.of(context).muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _lessons.isEmpty ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة لبحثك',
              style: TextStyle(
                  fontSize: 18, color: JisrColors.of(context).muted),
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
    final c = JisrColors.of(context);

    return Speakable(
      text: _buildLessonSpeech(lesson),
      radius: 16,
      onTap: null,
      child: Card(
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
                      color: c.tintGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.menu_book, size: 28, color: c.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (lesson['title'] ?? '').toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.heading,
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
                          if (content.isNotEmpty) 'محتوى الدرس: $content',
                        ].join('\n'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}