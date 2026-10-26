import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_plan_history.dart';
import '../../model/iep/iep_version.dart';
import 'iep_labels.dart';

class IepPlanCard extends StatelessWidget {
  const IepPlanCard({super.key, required this.plan, required this.onOpen});
  final IepPlan plan;
  final ValueChanged<IepVersion> onOpen;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(plan.title, style: Theme.of(context).textTheme.titleLarge),
            if (plan.closed) Text(l10n.iepClosed),
            if (plan.currentApprovedId == null) Text(l10n.iepNoApproved),
            if (plan.versions.isEmpty) Text(l10n.iepNoVersions),
            for (final version in plan.versions)
              OutlinedButton(
                key: ValueKey('iep-version-${version.id}'),
                onPressed: () => onOpen(version),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${l10n.iepVersionNumber}: ${version.number}'),
                    Text(iepStatusLabel(l10n, version.status)),
                    if (plan.currentApprovedId == version.id)
                      Text(l10n.iepCurrentApproved),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
