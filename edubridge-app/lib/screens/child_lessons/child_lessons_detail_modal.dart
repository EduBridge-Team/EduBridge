// lib/screens/child_lessons/child_lessons_detail_modal.dart
part of 'child_lessons_screen.dart';

Widget _buildLessonDetailModal({
  required BuildContext context,
  required String title,
  required String content,
  required Map lesson,
  VoidCallback? onReadSteps,
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
                  child: AdaptiveText(title, speechLanguageCode: ContentSpeechLanguage.resolve(title), type: AdaptiveTextType.title),
                ),
                IconButton(
                  tooltip: context.l10n.close,
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            if (images.isNotEmpty) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              ValueListenableBuilder<AccessibilityProfile>(
                valueListenable: AccessibilityService.instance.profile,
                builder: (context, profile, _) {
                  final rawDescriptions = lesson['image_descriptions'];
                  String descriptionFor(int index) {
                    if (rawDescriptions is List && index < rawDescriptions.length) {
                      final description = rawDescriptions[index]?.toString().trim();
                      if (description != null && description.isNotEmpty) return description;
                    }
                    return context.l10n.childLessonsImageFallback((index + 1).toString(), title);
                  }
                  if (profile.textOnlyMode) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (var i = 0; i < images.length; i++)
                        Padding(padding: const EdgeInsets.only(bottom: 8),
                          child: AltTextImage(imageUrl: images[i], altText: descriptionFor(i)))],
                    );
                  }
                  return SizedBox(height: 190, child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => SizedBox(width: AdaptiveHelper.spacing / 2),
                    itemBuilder: (_, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AltTextImage(imageUrl: images[index],
                        altText: descriptionFor(index), width: 250, height: 190),
                    ),
                  ));
                },
              ),
            ],

            if (onReadSteps != null) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveButton(label: context.l10n.childLessonsReadEasy, onPressed: onReadSteps),
            ],
            if (content.isNotEmpty) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveText(content, speechLanguageCode: ContentSpeechLanguage.resolve(content), type: AdaptiveTextType.body),
            ],

            if (audioDescription != null && audioDescription.isNotEmpty) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              _buildAudioDescBox(audioDescription),
            ],

            if (hasVideo) ...[
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveButton(
                label: context.l10n.childLessonsPlayVideo,
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
                    ? context.l10n.childLessonsStopAudio
                    : context.l10n.childLessonsPlayAudio,
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
              label: context.l10n.lessonRatingTitle,
              icon: Icons.star_outline,
              style: AdaptiveButtonStyle.outlined,
              onPressed: () {
                final lessonId = lesson['id'];
                if (lessonId is int) {
                  showLessonRatingSheet(context, lessonId: lessonId);
                }
              },
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),
            AdaptiveButton(
              label: context.l10n.lessonAskNoor,
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
              context.l10n.childLessonsAudioDescription(audioDescription),
              type: AdaptiveTextType.caption,
            ),
          ),
        ],
      ),
    ),
  );
}