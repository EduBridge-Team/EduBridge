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
            color: AppColors.brandBlueLight.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(AppIcons.parent,
                    color: AppColors.brandBlueLight, size: 32),
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
                          color: AppColors.brandBlueLight,
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
                style: const TextStyle(fontSize: 16, color: AppColors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
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
          Icon(AppIcons.lesson, size: 80, color: AppColors.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _lessons.isEmpty
                  ? 'لا توجد دروس مخصصة لأولياء الأمور بعد'
                  : 'لا نتائج مطابقة لبحثك',
              style: TextStyle(
                fontSize: 17,
                color: JisrColors.of(context).muted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_lessons.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'سيظهر هنا أي درس يضيفه المختص لأولياء الأمور',
                style: TextStyle(
                  fontSize: 13,
                  color: JisrColors.of(context).muted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
    final c = JisrColors.of(context);
    final isSpeaking = _speakingLessonId == lesson['id'];
    final content = (lesson['content'] ?? '').toString();
    final audioUrl = lesson['audio_url']?.toString();
    final videoUrl = lesson['video_url']?.toString();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasAudio = audioUrl != null && audioUrl.isNotEmpty;

    final rawImages =
        lesson['images'] ?? lesson['image_urls'] ?? const [];
    final images = rawImages is List
        ? rawImages
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

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
                    color: AppColors.brandBlueLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(AppIcons.parent,
                      size: 26, color: AppColors.brandBlueLight),
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

            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      width: 220,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 220,
                        height: 160,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(AppIcons.image, size: 42),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ],

            const SizedBox(height: 14),

            if (hasVideo) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlueLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(AppIcons.play, size: 26),
                  label: const Text(
                    'شاهد الفيديو',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdaptiveVideoPlayer(
                          videoUrl: videoUrl,
                          captionUrl: lesson['caption_url']?.toString(),
                          signLanguageUrl:
                              lesson['sign_language_url']?.toString(),
                          audioDescription:
                              lesson['audio_description']?.toString(),
                          title: (lesson['title'] ?? '').toString(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (hasAudio) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(
                        color: AppColors.green, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _activeAudioUrl == audioUrl
                        ? Icons.stop_circle_outlined
                        : Icons.headphones_outlined,
                    size: 22,
                  ),
                  label: Text(
                    _activeAudioUrl == audioUrl
                        ? 'إيقاف التسجيل'
                        : 'شغّل التسجيل الصوتي',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _toggleLessonAudio(audioUrl),
                ),
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(
                  isSpeaking
                      ? Icons.stop_circle_outlined
                      : AppIcons.volumeUp,
                  size: 24,
                ),
                label: Text(
                  isSpeaking ? 'إيقاف' : 'اسمع النص',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
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