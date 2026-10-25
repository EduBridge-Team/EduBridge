import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme.dart';

class StudentLearningMetricsCards extends StatelessWidget {
  const StudentLearningMetricsCards({
    super.key,
    required this.lessonsCount,
    required this.completionPercent,
  });

  final int? lessonsCount;
  final int? completionPercent;

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _metric(
            c,
            Icons.check_circle_outline,
            completionPercent == null ? '—' : '$completionPercent%',
            context.l10n.achievement,
            const Color(0xFF42B751),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _metric(
            c,
            Icons.menu_book_outlined,
            lessonsCount?.toString() ?? '—',
            context.l10n.lessons,
            const Color(0xFF1769C2),
          ),
        ),
      ],
    );
  }

  Widget _metric(
    JisrColors c,
    IconData icon,
    String value,
    String label,
    Color accent,
  ) => Container(
    constraints: const BoxConstraints(minHeight: 116),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: c.line),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: accent.withValues(alpha: .12),
          child: Icon(icon, color: accent, size: 19),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: c.heading,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
      ],
    ),
  );
}
