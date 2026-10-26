import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_draft.dart';

class IepDraftGoalCard extends StatelessWidget {
  const IepDraftGoalCard({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onRemove,
  });
  final IepDraftGoal goal;
  final VoidCallback onEdit, onRemove;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
            Text('${l.iepBaseline}: ${goal.baseline} ${goal.unit}'),
            Text('${l.iepTarget}: ${goal.target} ${goal.unit}'),
            Text('${l.iepMeasurement}: ${goal.method}'),
            if (goal.responsible.isNotEmpty)
              Text('${l.iepResponsible}: ${goal.responsible}'),
            Text('${l.academicStart}: ${day(goal.start)}'),
            Text('${l.academicEnd}: ${day(goal.end)}'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(onPressed: onEdit, child: Text(l.edit)),
                TextButton(onPressed: onRemove, child: Text(l.delete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
