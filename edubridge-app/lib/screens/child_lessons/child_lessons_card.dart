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
    content = SimpleLanguageService.instance.readingLines(content, wordsPerLine: 8);
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
                      BorderRadius.circular(AdaptiveHelper.cardRadius),
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
                      ? AppColors.brandTealDeep
                      : AdaptiveHelper.accentColor(context),
                ),
              ),
              SizedBox(width: AdaptiveHelper.spacing / 2),
              Expanded(
                child: AdaptiveText(
                  title,
                  type: AdaptiveTextType.subtitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (hasVideo)
                _mediaBadge(
                  icon: AppIcons.video,
                  label: 'فيديو',
                  color: AppColors.brandTealLight,
                )
              else if (hasAudio)
                _mediaBadge(
                  icon: AppIcons.audio,
                  label: 'صوت',
                  color: AppColors.brandTeal,
                ),
              if (isDone)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(AppIcons.check,
                      color: AppColors.brandTealDeep, size: 28),
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
          if (!isSample)
            Container(
              margin: EdgeInsets.only(bottom: AdaptiveHelper.spacing / 2),
              padding: EdgeInsets.symmetric(
                horizontal: AdaptiveHelper.spacing / 2,
                vertical: AdaptiveHelper.spacing / 3,
              ),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.green.withValues(alpha: .10)
                    : JisrColors.of(context).tintTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isDone ? AppIcons.check : AppIcons.lesson,
                    size: 16,
                    color: isDone
                        ? AppColors.brandTealDeep
                        : AppColors.brandBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AdaptiveText(
                      isDone ? 'تم إكمال هذا الدرس' : 'جاهز للبدء',
                      type: AdaptiveTextType.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
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
                        isDone ? AppColors.brandTealDeep : AppColors.brandTeal,
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