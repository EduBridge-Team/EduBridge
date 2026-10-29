import 'iep_goal_evidence.dart';

/// Observations, not a derived achievement score or an interpolated trend.
class IepMeasurementSeries {
  IepMeasurementSeries(IepEvidenceHistory history)
      : numeric = List.unmodifiable(history.entries.where((e) => e.measurement != null)),
        baseline = history.source.goal.baseline,
        target = history.source.goal.target;
  final List<IepGoalEvidence> numeric;
  final num baseline, target;
  IepGoalEvidence? get latest => numeric.isEmpty ? null : numeric.first;
  List<IepGoalEvidence> get plotted => List.unmodifiable(numeric.take(50).toList().reversed);
  double fraction(num value) {
    final values = <num>[baseline, target, ...plotted.map((e) => e.measurement!)];
    final scale = values.fold<double>(0, (a, b) => b.abs().toDouble() > a ? b.abs().toDouble() : a);
    if (scale == 0) return 0.5;
    final scaled = values.map((v) => v / scale);
    final low = scaled.reduce((a, b) => a < b ? a : b);
    final high = scaled.reduce((a, b) => a > b ? a : b);
    if (high == low) return 0.5;
    return ((value / scale - low) / (high - low)).clamp(0.0, 1.0).toDouble();
  }
  double dateFraction(DateTime date) {
    final points = plotted;
    if (points.length < 2) return 0.5;
    final span = _calendarDays(points.last.observedOn, points.first.observedOn);
    if (span == 0) return 0.5;
    return (_calendarDays(date, points.first.observedOn) / span).clamp(0.0, 1.0).toDouble();
  }
  int _calendarDays(DateTime a, DateTime b) => DateTime.utc(a.year, a.month, a.day)
      .difference(DateTime.utc(b.year, b.month, b.day)).inDays;
}

