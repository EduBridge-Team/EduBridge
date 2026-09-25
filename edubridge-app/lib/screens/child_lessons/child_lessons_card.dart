// lib/screens/child_lessons/child_lessons_card.dart
part of 'child_lessons_screen.dart';

Widget buildLessonCard({
  required BuildContext context,
  required Map lesson,
  required Set<int> doneLessonIds,
  required int? speakingLessonId,
  required int? savingLessonId,
  required bool canMarkDone,
  required void Function(Map lesson) onOpenLesson,
  required Future<void> Function(Map lesson) onToggleSpeak,
  required Future<void> Function(int lessonId) onMarkDone,
}) {
  final rawId = lesson['id'];
  final int lessonId = (rawId is int) ? rawId : -999;

  final isDone = doneLessonIds.contains(lessonId);
  final isSpeaking = speakingLessonId == lessonId;
  final isSaving = savingLessonId == lessonId;
  final isSample = lessonId < 0;

  final videoUrl = lesson['video_url']?.toString();
  final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
  final hasAudio = (lesson['audio_url']?.toString().isNotEmpty ?? false);

  final profile = AccessibilityService.instance.profile.value;
  var title = (lesson['title'] ?? '').toString();
  var content = (lesson['content'] ?? '').toString();

  if (profile.verySimpleLanguage) {
    title = SimpleLanguageService.instance.simplify(title);
    content = SimpleLanguageService.instance.simplify(content);
  }
  if (profile.shortSentences) {
    content = SimpleLanguageService.instance.shorten(content, maxWords: 10);
  }

  return Padding(
    padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
    child: AdaptiveCard(
      onTap: isSample ? null : () => onOpenLesson(lesson),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AdaptiveHelper.iconSize + 20,
                height: AdaptiveHelper.iconSize + 20,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.green.withValues(alpha: 0.15)
                      : AdaptiveHelper.accentColor(context)
                          .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AdaptiveHelper.cardRadius - 8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isDone
                      ? AppIcons.check
                      : hasVideo
                          ? AppIcons.play
                          : hasAudio
                              ? AppIcons.volumeUp
                              : AppIcons.lesson,
                  size: AdaptiveHelper.iconSize,
                  color: isDone
                      ? AppColors.green
                      : AdaptiveHelper.accentColor(context),
                ),
              ),
              SizedBox(width: AdaptiveHelper.spacing / 2),
              Expanded(
                child: AdaptiveText(
                  title,
                  type: AdaptiveTextType.subtitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasVideo)
                _mediaBadge(
                  icon: AppIcons.video,
                  label: 'فيديو',
                  color: AppColors.pink,
                )
              else if (hasAudio)
                _mediaBadge(
                  icon: AppIcons.audio,
                  label: 'صوت',
                  color: AppColors.green,
                ),
              if (isDone)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(AppIcons.check,
                      color: AppColors.green, size: 28),
                ),
            ],
          ),
          if (content.isNotEmpty) ...[
            SizedBox(height: AdaptiveHelper.spacing / 2),
            AdaptiveText(
              content,
              type: AdaptiveTextType.body,
              maxLines: 3,
            ),
          ],
          SizedBox(height: AdaptiveHelper.spacing),
          Row(
            children: [
              Expanded(
                child: AdaptiveButton(
                  label: isSpeaking ? 'إيقاف' : 'استمع',
                  icon: isSpeaking ? Icons.stop_circle : AppIcons.volumeUp,
                  style: AdaptiveButtonStyle.outlined,
                  fullWidth: true,
                  onPressed: () => onToggleSpeak(lesson),
                ),
              ),
              if (canMarkDone && !isSample) ...[
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: isDone ? 'مكتمل' : 'تمّ',
                    icon: isDone ? AppIcons.check : Icons.check,
                    backgroundColor:
                        isDone ? AppColors.greenDeep : AppColors.green,
                    fullWidth: true,
                    onPressed: (isDone || isSaving)
                        ? null
                        : () => onMarkDone(lessonId),
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

Widget _mediaBadge({
  required IconData icon,
  required String label,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}