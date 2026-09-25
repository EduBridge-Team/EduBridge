part of 'parent_lessons_screen.dart';

extension _ParentLessonsWidgets on _ParentLessonsScreenState {
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
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(AppIcons.parent,
                      size: 26, color: AppColors.purple),
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
                    backgroundColor: AppColors.purple,
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
