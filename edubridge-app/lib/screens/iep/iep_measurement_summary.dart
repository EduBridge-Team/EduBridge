import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/iep/iep_goal_evidence.dart';
import '../../model/iep/iep_measurement_series.dart';
import 'iep_evidence_labels.dart';
import 'iep_measurement_plot.dart';

class IepMeasurementSummary extends StatelessWidget {
  const IepMeasurementSummary({super.key, required this.history});
  final IepEvidenceHistory history;
  @override
  Widget build(BuildContext context) {
    final l = IepEvidenceLabels(context), goal = history.source.goal;
    final series = IepMeasurementSeries(history), dates = MaterialLocalizations.of(context);
    final latest = series.latest;
    return Card(key: const ValueKey('iep-measurement-summary'), child: Padding(
      padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.measurementSummary, style: Theme.of(context).textTheme.titleLarge),
        Text('${context.l10n.iepBaseline}: ${goal.baseline} ${goal.unit}'),
        Text('${context.l10n.iepTarget}: ${goal.target} ${goal.unit}'),
        Text('${l.latestMeasurement}: ${latest == null ? '—' : '${latest.measurement} ${goal.unit}'}',
            key: const ValueKey('iep-latest-measurement')),
        if (latest != null) Text('${l.date}: ${dates.formatFullDate(latest.observedOn)}'),
        Text(l.measurementCaution),
        if (series.numeric.isEmpty) Text(l.noMeasurements),
        if (series.numeric.isNotEmpty) ...[
          Text(l.plotTitle, style: Theme.of(context).textTheme.titleMedium),
          Text(l.plotLegend),
          Semantics(label: l.plotAccessible, child: ExcludeSemantics(
            child: IepMeasurementPlot(series: series))),
          Text(l.plotLimit),
          ExpansionTile(key: const ValueKey('iep-measurement-table'),
            title: Text(l.measurementTable),
            children: [for (final entry in series.numeric) Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(dates.formatFullDate(entry.observedOn)),
                Text('${entry.measurement} ${goal.unit}'),
                Text('${l.source}: ${entry.sourceLabel}'),
                if (entry.author?.trim().isNotEmpty == true) Text('${l.author}: ${entry.author}'),
              ]))]),
        ],
      ])));
  }
}

