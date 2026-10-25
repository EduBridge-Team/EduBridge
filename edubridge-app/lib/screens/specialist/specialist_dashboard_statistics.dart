import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';

class SpecialistDashboardStatistics extends StatelessWidget {
  const SpecialistDashboardStatistics({
    super.key,
    required this.pending,
    required this.doneToday,
    required this.inProgress,
  });

  final int pending;
  final int doneToday;
  final int inProgress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        _StatsCard(
          value: '$pending',
          label: context.l10n.awaitingAssessment,
          color: AppColors.blue,
        ),
        const SizedBox(width: 7),
        _StatsCard(
          value: '$doneToday',
          label: context.l10n.completedToday,
          color: AppColors.brandTealDeep,
        ),
        const SizedBox(width: 7),
        _StatsCard(
          value: '$inProgress',
          label: context.l10n.inProgress,
          color: AppColors.brandTeal,
        ),
      ],
    ),
  );
}

class _StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatsCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D3C6C).withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
