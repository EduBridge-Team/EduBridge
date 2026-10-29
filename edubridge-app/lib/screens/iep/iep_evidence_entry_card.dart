import 'package:flutter/material.dart';
import '../../model/iep/iep_goal_evidence.dart';
import 'iep_evidence_labels.dart';

class IepEvidenceEntryCard extends StatelessWidget {
  const IepEvidenceEntryCard({super.key, required this.entry, required this.unit});
  final IepGoalEvidence entry;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final labels = IepEvidenceLabels(context);
    final dates = MaterialLocalizations.of(context);
    final recorded = entry.recordedAt.toLocal();
    return Card(child: Padding(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SelectableText('${labels.source}: ${entry.sourceLabel}',
            style: Theme.of(context).textTheme.titleMedium),
        Text('${labels.date}: ${dates.formatFullDate(entry.observedOn)}'),
        Text('${labels.recorded}: ${dates.formatMediumDate(recorded)} '
            '${dates.formatTimeOfDay(TimeOfDay.fromDateTime(recorded))}'),
        if (entry.author?.trim().isNotEmpty == true)
          SelectableText('${labels.author}: ${entry.author}'),
        SelectableText('${labels.observation}: ${entry.observation}'),
        Text('${labels.measurement}: ${entry.measurement == null ? '—' : '${entry.measurement} $unit'}',
            key: ValueKey('iep-evidence-measurement-${entry.id}')),
      ])));
  }
}

