import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_goal_evidence.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'iep_goal_evidence_fixture.dart';

void main() {
  test('reads exact goal path, preserves qualitative and zero measurements, sorts immutable history', () async {
    final source = evidenceSource(), f = EvidenceFixture(evidenceSource());
    final history = await f.repository.load(source);
    expect(f.paths.single, '/children/${source.childId}/iep-plans/${source.planId}/versions/${source.goal.versionId}/goals/${source.goal.id}/evidence');
    expect(history.entries.map((e) => e.id), [2, 1]);
    expect(history.entries.first.measurement, 0);
    expect(history.entries.last.measurement, isNull);
    expect(history.entries.last.observation, 'ملاحظة وصفية أصلية');
    expect(() => history.entries.clear(), throwsUnsupportedError);
  });
  for (final field in ['child_id', 'plan_id', 'plan_version_id', 'goal_id']) {
    test('rejects foreign $field', () async {
      final source = evidenceSource(), f = EvidenceFixture(evidenceSource());
      f.data[field] = 999999;
      await expectLater(f.repository.load(source),
          throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    });
  }
  for (final mode in ['contract', 'partial', 'revision', 'unit', 'duplicate', 'text', 'date', 'timestamp', 'timezone', 'measurement-unit', 'missing-measurement']) {
    test('rejects invalid history $mode', () async {
      final source = evidenceSource(), f = EvidenceFixture(evidenceSource());
      final entries = f.data['evidence'] as List;
      final first = entries.first as Map<String, dynamic>;
      switch (mode) {
        case 'contract': f.data['contract_version'] = 2;
        case 'partial': f.data['complete'] = false;
        case 'revision': f.data['revision'] = '';
        case 'unit': f.data['unit'] = 'unrelated';
        case 'duplicate': entries.add(evidenceCopy(first));
        case 'text': first['observation'] = '';
        case 'date': first['observed_on'] = '2026-02-30';
        case 'timestamp': first['recorded_at'] = '2026-10-01T25:00:00Z';
        case 'timezone': first['recorded_at'] = '2026-10-01T12:00:00';
        case 'measurement-unit': first['measurement'] = 0;
        case 'missing-measurement': first['unit'] = source.goal.unit;
      }
      await expectLater(f.repository.load(source), throwsA(isA<EnrollmentApiException>()));
    });
  }
  test('rejects non-finite measurement and preserves complete empty history', () {
    final source = evidenceSource(), data = evidenceJson(evidenceSource());
    final entry = (data['evidence'] as List).last as Map<String, dynamic>;
    entry['measurement'] = double.infinity;
    expect(() => IepEvidenceHistory.fromJson(source, data), throwsFormatException);
    data['evidence'] = <Object>[];
    expect(IepEvidenceHistory.fromJson(source, data).entries, isEmpty);
  });
  for (final code in [401, 403, 404, 501]) {
    test('server denial or unavailable $code is never empty success', () async {
      final source = evidenceSource(), f = EvidenceFixture(evidenceSource())..status = code;
      await expectLater(f.repository.load(source), throwsA(isA<EnrollmentApiException>()));
      expect(f.paths, hasLength(1));
    });
  }
}

