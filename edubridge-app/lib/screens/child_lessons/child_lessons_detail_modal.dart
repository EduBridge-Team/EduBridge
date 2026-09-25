// lib/screens/child_lessons/child_lessons_detail_modal.dart
part of 'child_lessons_screen.dart';

Widget _buildLessonDetailModal({
  required BuildContext context,
  required String title,
  required String content,
  required Map lesson,
  required String? activeAudioUrl,
  required Future<void> Function(String url) onToggleAudio,
  required void Function(String title, String content) onOpenAssistant,
  required void Function({
    required String videoUrl,
    String? captionUrl,
    String? signLanguageUrl,
    String? audioDescription,
    required String title,
  }) onOpenVideo,
}) {
  final videoUrl = lesson['video_url']?.toString();
  final audioUrl = lesson['audio_url']?.toString();
  final captionUrl = lesson['caption_url']?.toString();
  final signLanguageUrl = lesson['sign_language_url']?.toString();
  final audioDescription = lesson['audio_description']?.toString();

  final rawImages = lesson['images'] ?? lesson['image_urls'] ?? const [];
  final images = rawImages is List
      ? rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
      : <String>[];

  final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
  final hasAudio = audioUrl != null && audioUrl.isNotEmpty;

  return SafeArea(
    child: Container(
      margin: EdgeInsets.all(AdaptiveHelper.spacing),
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
                  child: AdaptiveText(title, type: AdaptiveTextType.title),
                ),
                IconButton(
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            if (images.isNotEmpty) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: AdaptiveHelper.spacing / 2),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      images[index],
                      width: 250,
                      height: 190,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 250,
                        height: 190,
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
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveText(content, type: AdaptiveTextType.body),
            ],

            if (audioDescription != null && audioDescription.isNotEmpty) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              _buildAudioDescBox(audioDescription),
            ],

            if (hasVideo) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveButton(
                label: 'تشغيل فيديو الدرس',
                icon: AppIcons.play,
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  onOpenVideo(
                    videoUrl: videoUrl,
                    captionUrl:
                        captionUrl != null && captionUrl.isNotEmpty
                            ? captionUrl
                            : null,
                    signLanguageUrl:
                        signLanguageUrl != null && signLanguageUrl.isNotEmpty
                            ? signLanguageUrl
                            : null,
                    audioDescription:
                        audioDescription != null && audioDescription.isNotEmpty
                            ? audioDescription
                            : null,
                    title: title,
                  );
                },
              ),
            ],

            if (hasAudio) ...[
              SizedBox(height: AdaptiveHelper.spacing / 2),
              AdaptiveButton(
                label: activeAudioUrl == audioUrl
                    ? 'إيقاف التسجيل الصوتي'
                    : 'تشغيل التسجيل الصوتي',
                icon: activeAudioUrl == audioUrl
                    ? Icons.stop
                    : AppIcons.volumeUp,
                style: AdaptiveButtonStyle.outlined,
                fullWidth: true,
                onPressed: () => onToggleAudio(audioUrl),
              ),
            ],

            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: 'اسأل نور',
              icon: AppIcons.speech,
              style: AdaptiveButtonStyle.outlined,
              onPressed: () {
                Navigator.pop(context);
                onOpenAssistant(title, content);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildAudioDescBox(String audioDescription) {
  return Builder(
    builder: (context) => Container(
      width: double.infinity,
      padding: EdgeInsets.all(AdaptiveHelper.spacing / 1.5),
      decoration: BoxDecoration(
        color: AppColors.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.speech, color: AppColors.brandTeal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: AdaptiveText(
              'الوصف الصوتي: $audioDescription',
              type: AdaptiveTextType.caption,
            ),
          ),
        ],
      ),
    ),
  );
}