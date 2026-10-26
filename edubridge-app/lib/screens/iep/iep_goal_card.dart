import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_goal.dart';

class IepGoalCard extends StatelessWidget {
  const IepGoalCard({super.key, required this.goal});
  final IepGoal goal;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              goal.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${l10n.iepBaseline}: ${goal.baseline} ${goal.unit}'),
            Text('${l10n.iepTarget}: ${goal.target} ${goal.unit}'),
            SelectableText('${l10n.iepMeasurement}: ${goal.method}'),
            if (goal.responsible?.trim().isNotEmpty == true)
              SelectableText('${l10n.iepResponsible}: ${goal.responsible}'),
            Text(
              '${dates.formatMediumDate(goal.start)} — ${dates.formatMediumDate(goal.end)}',
            ),
          ],
        ),
      ),
    );
  }
}
