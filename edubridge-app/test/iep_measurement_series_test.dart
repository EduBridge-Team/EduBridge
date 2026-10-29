import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_goal.dart';
import 'package:edubridge_app/model/iep/iep_goal_evidence.dart';
import 'package:edubridge_app/model/iep/iep_measurement_series.dart';
import 'package:edubridge_app/model/iep/iep_evidence_filter.dart';
import 'iep_goal_evidence_fixture.dart';

IepEvidenceSource measuredSource(num baseline, num target) {
  final source = evidenceSource(), old = source.goal;
  final goal = IepGoal.fromJson({
    'id': old.id, 'plan_version_id': old.versionId, 'title': old.title,
    'baseline': baseline, 'target': target, 'unit': old.unit,
    'measurement_method': old.method, 'starts_on': '2026-09-01', 'ends_on': '2027-06-01',
  });
  return IepEvidenceSource(childId: source.childId, planId: source.planId, goal: goal);
}
void main() {
  test('qualitative evidence is not zero; explicit zero is the latest measurement', () {
    final source = evidenceSource(), data = evidenceJson(evidenceSource());
    final history = IepEvidenceHistory.fromJson(source, data), series = IepMeasurementSeries(history);
    expect(series.numeric, hasLength(1)); expect(series.latest!.measurement, 0);
    data['evidence'] = [(data['evidence'] as List).first];
    final qualitative = IepMeasurementSeries(IepEvidenceHistory.fromJson(source, data));
    expect(qualitative.latest, isNull); expect(qualitative.numeric, isEmpty);
  });
  for (final pair in [(0, 0), (5, 5), (1e308, -1e308)]) {
    test('normalizes equal and extreme finite reference values $pair without overflow', () {
      final source = measuredSource(pair.$1, pair.$2), data = evidenceJson(source);
      final series = IepMeasurementSeries(IepEvidenceHistory.fromJson(source, data));
      for (final value in [source.goal.baseline, source.goal.target, 0]) {
        expect(series.fraction(value).isFinite, isTrue);
        expect(series.fraction(value), inInclusiveRange(0.0, 1.0));
      }
    });
  }
  test('plot caps at 50 but all measurements are retained and dates are proportional', () {
    final source = evidenceSource(), data = evidenceJson(evidenceSource());
    data['evidence'] = List.generate(61, (i) => {
      'id': i + 1, 'source_label': 'جلسة', 'observation': 'قياس موثق',
      'observed_on': DateTime(2026, 10, 1).add(Duration(days: i)).toIso8601String().substring(0, 10),
      'recorded_at': '2026-12-01T12:00:00Z', 'measurement': i, 'unit': source.goal.unit,
    });
    final series = IepMeasurementSeries(IepEvidenceHistory.fromJson(source, data));
    expect(series.numeric, hasLength(61)); expect(series.plotted, hasLength(50));
    expect(series.latest!.id, 61); expect(series.plotted.first.id, 12);
    expect(series.dateFraction(series.plotted.first.observedOn), 0);
    expect(series.dateFraction(series.plotted.last.observedOn), 1);
    expect(() => series.numeric.clear(), throwsUnsupportedError);
  });
  test('filters keep authored content, zero measurements and deterministic ordering', () {
    final source = evidenceSource(), history = IepEvidenceHistory.fromJson(source, evidenceJson(source));
    expect(filterIepEvidence(history, IepEvidenceKind.numeric, '', false).single.id, 2);
    expect(filterIepEvidence(history, IepEvidenceKind.qualitative, '', false).single.id, 1);
    expect(filterIepEvidence(history, IepEvidenceKind.all, ' المختص ', false).single.id, 1);
    expect(filterIepEvidence(history, IepEvidenceKind.all, '', true).map((e) => e.id), [1, 2]);
    expect(filterIepEvidence(history, IepEvidenceKind.all, 'no match', false), isEmpty);
    expect(history.entries.map((e) => e.id), [2, 1]);
  });
}

