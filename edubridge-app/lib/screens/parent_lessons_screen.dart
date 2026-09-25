// lib/screens/parent_lessons_screen.dart
// دروس مخصصة لأولياء الأمور
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/accessibility/adaptive_video_player.dart';

part 'parent_lessons_widgets.dart';

class ParentLessonsScreen extends StatefulWidget {
  const ParentLessonsScreen({super.key});

  @override
  State<ParentLessonsScreen> createState() => _ParentLessonsScreenState();
}

class _ParentLessonsScreenState extends State<ParentLessonsScreen> {
  List _lessons = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  int? _speakingLessonId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeAudioUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/lessons?target_type=parents');
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
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

  Future<void> _toggleSpeak(Map lesson) async {
    final id = lesson['id'];
    if (_speakingLessonId == id) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.stop();
    if (!mounted) return;
    setState(() => _speakingLessonId = id is int ? id : null);

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

  Future<void> _toggleLessonAudio(String url) async {
    if (_activeAudioUrl == url) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _activeAudioUrl = null);
      return;
    }
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
    if (mounted) setState(() => _activeAudioUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(
        title: 'دروس لولي الأمر',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            tooltip: 'تحديث',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // رأس توضيحي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.purple.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(AppIcons.parent,
                    color: AppColors.purple, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'دروس مخصصة لك',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نصائح وإرشادات من المختصين لمساعدتك في التعامل مع ابنك',
                        style: TextStyle(
                          fontSize: 13,
                          color: JisrColors.of(context).muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // بحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              style: const TextStyle(fontSize: 17),
              decoration: const InputDecoration(
                hintText: 'ابحث في الدروس...',
                prefixIcon: Icon(AppIcons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }
}
