import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_enrollment_history_fixture.dart';

void main() {
  test('actual scoped endpoint sorts history and preserves nullable dates', () async {
    final fixture = InstitutionHistoryFixture();
    fixture.rows = [fixture.rows.last, fixture.rows.first];
    final data = await fixture.repository.load();
    expect(data.records.map((v) => v.id), [2, 1]);
    expect(data.records.first.childName, 'نور');
    expect(data.records.first.end, isNull);
    expect(data.sectionLabel(30), contains('الصف الثاني'));
    expect(fixture.paths, hasLength(3));
    expect(() => data.records.clear(), throwsUnsupportedError);
    fixture.rows.first['enrolled_on'] = null;
    expect((await fixture.repository.load()).records.last.start, isNull);
  });
  for (final failure in ['scope', 'year', 'duplicate', 'status', 'date', 'context']) {
    test('rejects $failure history', () async {
      final fixture = InstitutionHistoryFixture();
      switch (failure) {
        case 'scope': fixture.rows.first['section_id'] = 999; break;
        case 'year': fixture.rows.first['academic_year_id'] = 999; break;
        case 'duplicate': fixture.rows.add(Map.from(fixture.rows.first)); break;
        case 'status': fixture.rows.first['status'] = 'unknown'; break;
        case 'date': fixture.rows.first['enrolled_on'] = '2026-02-30'; break;
        case 'context': fixture.academic.slug = 'other-institution'; break;
      }
      await expectLater(fixture.repository.load(), throwsA(isA<EnrollmentApiException>()));
    });
  }
}
