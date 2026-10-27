import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'institution_attendance_fixture.dart';

void main() {
  test('report parses PostgreSQL aggregates and forwards exact filters', () async {
    final f = InstitutionAttendanceFixture();
    final data = await f.repository.loadReport(from: DateTime(2026, 10, 1, 12), to: DateTime(2026, 10, 26), sectionId: 30);
    expect(data.students.single.rate, 50); expect(data.summary['present'], 2);
    final uri = Uri.parse(f.paths.last);
    expect(uri.path, '/institutions/demo-institution/schools/5/attendance/report');
    expect(uri.queryParameters, {'from': '2026-10-01', 'to': '2026-10-26', 'section_id': '30'});
    expect(() => data.summary['present'] = 99, throwsUnsupportedError);
    expect(() => data.students.clear(), throwsUnsupportedError);
    expect(f.posts, isEmpty); expect(f.puts, isEmpty);
  });
  test('invalid dates, unknown section and foreign institution do not request report', () async {
    final f = InstitutionAttendanceFixture();
    await expectLater(f.repository.loadReport(from: DateTime(2026, 10, 26), to: DateTime(2026, 10, 1)), throwsA(isA<EnrollmentApiException>()));
    await expectLater(f.repository.loadReport(sectionId: 999), throwsA(isA<EnrollmentApiException>()));
    (f.academic.data['school'] as Map)['organization_id'] = 99;
    await expectLater(f.repository.loadReport(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.forbidden)));
    expect(f.paths.where((p) => p.contains('/attendance/report')), isEmpty);
  });
  test('empty and denied reports are distinct', () async {
    final f = InstitutionAttendanceFixture();
    f.report = {'summary': {'present': 0, 'absent': 0, 'late': 0, 'excused': 0}, 'students': []};
    expect((await f.repository.loadReport()).students, isEmpty);
    f.status = 403;
    await expectLater(f.repository.loadReport(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.forbidden)));
  });
  test('malformed, duplicate or inconsistent totals are rejected', () async {
    for (final mode in ['negative', 'missing', 'decimal', 'total', 'rate', 'duplicate', 'summary']) {
      final f = InstitutionAttendanceFixture();
      final rows = f.report['students'] as List;
      final row = rows.single as Map;
      switch (mode) {
        case 'negative': row['present_count'] = -1;
        case 'missing': row.remove('present_count');
        case 'decimal': row['present_count'] = '2.5';
        case 'total': row['total_sessions'] = 5;
        case 'rate': row['attendance_rate'] = 75;
        case 'duplicate': rows.add(Map<String, dynamic>.from(row));
        case 'summary': (f.report['summary'] as Map)['present'] = 9;
      }
      await expectLater(f.repository.loadReport(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    }
  });
}
