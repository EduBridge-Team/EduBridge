// lib/screens/child_lessons/child_lessons_header.dart
part of 'child_lessons_screen.dart';

PreferredSizeWidget buildChildLessonsAppBar({
  required BuildContext context,
  required String childName,
  required int stars,
  required VoidCallback onOpenSettings,
  required VoidCallback onOpenProgress,
}) {
  return AppBar(
    flexibleSpace: Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    ),
    title: Text(
      'دروس $childName',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
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
          borderRadius: BorderRadius.circular(20),
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
      IconButton(
        icon: const Icon(Icons.accessibility_new, color: Colors.white),
        tooltip: 'إعدادات التكييف',
        onPressed: onOpenSettings,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      IconButton(
        icon: const Icon(AppIcons.progress, color: Colors.white),
        tooltip: 'التقدّم',
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
  required String childName,
  required String? parentPhone,
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
              profile.type == DisabilityType.blind
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
                    profile.type == DisabilityType.blind
                        ? 'ألعاب سمعية'
                        : 'الألعاب التعليمية',
                    type: AdaptiveTextType.subtitle,
                    color: Colors.white,
                  ),
                  SizedBox(height: AdaptiveHelper.spacing / 4),
                  const AdaptiveText(
                    'العب وتعلّم',
                    type: AdaptiveTextType.caption,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: Colors.white, size: 32),
          ],
        ),
      ),
    ),
  );

  if (profile.visualTimerEnabled && !profile.noTimers) {
    final timerMinutes =
        (profile.timerRenewalMinutes > 0) ? profile.timerRenewalMinutes : 5;
    items.add(
      Padding(
        padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
        child: profile.type == DisabilityType.blind
            ? AudioTimer(
                key: ValueKey('audio_timer_cycle_$timerCycle'),
                total: Duration(minutes: timerMinutes),
                childName: childName,
                onFinished: () async {
                  TtsService.instance.speakLine('انتهى الوقت! وقت الراحة');
                  await BrainBreakDialog.show(context);
                  onTimerFinished();
                },
              )
            : Center(
                child: VisualTimer(
                  key: ValueKey('timer_cycle_$timerCycle'),
                  total: Duration(minutes: timerMinutes),
                  label: 'وقت القراءة المتبقي',
                  showControls: true,
                  onFinished: () async {
                    await VisualCelebration.show(
                      context,
                      message: 'أحسنت! انتهت $timerMinutes دقائق',
                      icon: AppIcons.clock, 
                      childName: childName,
                      duration: const Duration(seconds: 2),
                    );
                    await BrainBreakDialog.show(context);
                    onTimerFinished();
                  },
                ),
              ),
      ),
    );
  }

  if (profile.predictableTimeline) {
    items.add(
      Padding(
        padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
        child: VisualTimeline(
          title: 'خطوات الدرس',
          steps: [
            const TimelineStep(
              icon: AppIcons.lesson, 
              label: 'اقرأ العنوان',
              done: true,
            ),
            TimelineStep(
              icon: AppIcons.audio, 
              label: 'استمع للشرح',
              current: !canMarkDone, 
            ),
            TimelineStep(
              icon: AppIcons.homework, 
              label: 'حلّ التمرين',
              done: canMarkDone,
            ),
            const TimelineStep(
              icon: AppIcons.starFilled, 
              label: 'احصل على نجمة',
            ),
          ],
        ),
      ),
    );
  }

  if (profile.emergencyButton) {
    items.add(
      EmergencyButton(
        childName: childName,
        parentPhone: parentPhone,
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: items,
  );
}

Widget buildSampleBanner() {
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
              children: const [
                AdaptiveText(
                  'دروس تجريبية',
                  type: AdaptiveTextType.body,
                  fontWeight: FontWeight.bold,
                ),
                AdaptiveText(
                  'عندما تُضاف دروس حقيقية، ستظهر هنا',
                  type: AdaptiveTextType.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}