// lib/screens/child_lessons/child_lessons_header.dart
part of 'child_lessons_screen.dart';

PreferredSizeWidget buildChildLessonsAppBar({
  required BuildContext context,
  required String childName,
  required int stars,
  required VoidCallback? onOpenSettings,
  required VoidCallback onOpenProgress,
}) {
  return BrandAppBar(
    title: Text(
      context.l10n.childLessonsFor(childName),
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
    centerTitle: false,
    actions: [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.starFilled, size: 16, color: AppColors.yellow),
            const SizedBox(width: 3),
            Text(
              '$stars',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      if (onOpenSettings != null) IconButton(
        icon: const Icon(Icons.accessibility_new, color: Colors.white),
        tooltip: context.l10n.childLessonsSettings,
        onPressed: onOpenSettings,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      IconButton(
        icon: const Icon(AppIcons.progress, color: Colors.white),
        tooltip: context.l10n.progress,
        onPressed: onOpenProgress,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      const SizedBox(width: 4),
    ],
  );
}

Widget buildAdaptiveHeader({
  required BuildContext context,
  required int childId,
  required String childName,
  required String? parentPhone,
  required String? specialistPhone,
  required bool canMarkDone,
  required int timerCycle,
  required VoidCallback onOpenGames,
  required VoidCallback onTimerFinished,
}) {
  final profile = AccessibilityService.instance.profile.value;
  final items = <Widget>[];

  items.add(
    Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        onTap: onOpenGames,
        backgroundColor: AdaptiveHelper.accentColor(context),
        child: Row(
          children: [
            Icon(
              profile.screenReaderOptimized
                  ? AppIcons.deaf
                  : AppIcons.game,
              size: AdaptiveHelper.iconSize + 10,
              color: Colors.white,
            ),
            SizedBox(width: AdaptiveHelper.spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveText(
                    profile.screenReaderOptimized
                        ? context.l10n.childLessonsAudioGames
                        : context.l10n.childLessonsGames,
                    type: AdaptiveTextType.subtitle,
                    color: Colors.white,
                  ),
                  SizedBox(height: AdaptiveHelper.spacing / 4),
                  AdaptiveText(
                    context.l10n.childLessonsPlayLearn,
                    type: AdaptiveTextType.caption,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: Colors.white, size: 32),
          ],
        ),
      ),
    ),
  );

  if (profile.visualTimerEnabled && AdaptiveFeedbackPolicy(profile).allowTaskDeadline) {
    final timerMinutes =
        (profile.timerRenewalMinutes > 0) ? profile.timerRenewalMinutes : 5;
    items.add(
      Padding(
        padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
        child: profile.screenReaderOptimized
            ? AudioTimer(
                key: ValueKey('audio_timer_cycle_$timerCycle'),
                total: Duration(minutes: timerMinutes),
                childName: childName,
                onFinished: () async {
                  if (AdaptiveFeedbackPolicy(profile).allowAutomaticSpeech) {
                    AdaptiveHelper.speak(context.l10n.childLessonsBreakTime);
                  }
                  await BrainBreakDialog.show(context);
                  onTimerFinished();
                },
              )
            : Center(
                child: VisualTimer(
                  key: ValueKey('timer_cycle_$timerCycle'),
                  total: Duration(minutes: timerMinutes),
                  label: context.l10n.childLessonsTimeRemaining,
                  showControls: true,
                  onFinished: () async {
                    await VisualCelebration.show(
                      context,
                      message: context.l10n.childLessonsTimerFinished(timerMinutes.toString()),
                      emoji: '⏰',
                      childName: childName,
                      duration: const Duration(seconds: 2),
                    );
                    if (!context.mounted) return;
                    await BrainBreakDialog.show(context);
                    onTimerFinished();
                  },
                ),
              ),
      ),
    );
  }

  if (profile.predictableTimeline || profile.routineStructure) {
    items.add(
      Padding(
        padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
        child: VisualTimeline(
          title: context.l10n.childLessonsTimeline,
          steps: [
            TimelineStep(emoji: '📖', label: context.l10n.childLessonsChoose),
            TimelineStep(emoji: '🎧', label: context.l10n.childLessonsListenHelp),
            TimelineStep(emoji: '✍️', label: context.l10n.childLessonsTry),
            TimelineStep(emoji: '🌿', label: context.l10n.childLessonsReview),
          ],
        ),
      ),
    );
  }

  if (profile.emergencyButton) {
    items.add(
      EmergencyButton(
        childId: childId,
        childName: childName,
        parentPhone: parentPhone,
        specialistPhone: specialistPhone,
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: items,
  );
}

Widget buildSampleBanner() => Builder(builder: (context) {
  return Padding(
    padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
    child: AdaptiveCard(
      child: Row(
        children: [
          const Icon(AppIcons.info, color: AppColors.orange, size: 28),
          SizedBox(width: AdaptiveHelper.spacing / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdaptiveText(
                  context.l10n.childLessonsSample,
                  type: AdaptiveTextType.body,
                  fontWeight: FontWeight.bold,
                ),
                AdaptiveText(
                  context.l10n.childLessonsSampleHint,
                  type: AdaptiveTextType.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
});
