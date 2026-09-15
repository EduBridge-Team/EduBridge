// خط زمني بصري ثابت — يُظهر ما تم إنجازه وما هو التالي
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../theme.dart';

class TimelineStep {
  final String emoji;
  final String label;
  final bool done;
  final bool current;

  const TimelineStep({
    required this.emoji,
    required this.label,
    this.done = false,
    this.current = false,
  });
}

class VisualTimeline extends StatelessWidget {
  final List<TimelineStep> steps;
  final String? title;

  const VisualTimeline({super.key, required this.steps, this.title});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large = AccessibilityService.instance.profile.value
        .extraLargeTouchTargets;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: large ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
            ),
          ...steps.map((step) => _TimelineRow(step: step, large: large)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineStep step;
  final bool large;
  const _TimelineRow({required this.step, required this.large});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final size = large ? 60.0 : 46.0;

    Color bg;
    Color fg;
    if (step.done) {
      bg = c.tintGreen;
      fg = c.success;
    } else if (step.current) {
      bg = AppColors.tintOrange;
      fg = AppColors.orangeDeep;
    } else {
      bg = c.card;
      fg = c.muted;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: large ? 10 : 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(size / 3),
              border: Border.all(
                color: step.current ? AppColors.orange : c.line,
                width: step.current ? 2.5 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              step.done ? '✓' : step.emoji,
              style: TextStyle(
                fontSize: large ? 26 : 22,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: large ? 20 : 16,
                fontWeight: step.current ? FontWeight.bold : FontWeight.w500,
                color: step.done ? c.muted : c.body,
                decoration: step.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (step.current)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('الآن',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}