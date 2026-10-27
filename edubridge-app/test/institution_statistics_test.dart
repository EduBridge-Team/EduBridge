import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'institution_statistics_fixture.dart';

void main() {
  test('report resolves scope and encodes inclusive dates without writes', () async {
    final f = InstitutionStatisticsFixture();
    final data = await f.repository.load(from: DateTime(2026, 10, 1, 12), to: DateTime(2026, 10, 26));
    expect(data.organizationId, 4); expect(data.schools.single.name, 'مدرسة الأمل');
    expect(Uri.parse(f.paths[1]).queryParameters, {'from': '2026-10-01', 'to': '2026-10-26'});
    expect(data.summary['student_files'], 10);
    expect(() => data.summary['schools'] = 4, throwsUnsupportedError);
    expect(() => data.schools.clear(), throwsUnsupportedError);
  });
  test('reversed range is rejected before transport', () async {
    final f = InstitutionStatisticsFixture();
    await expectLater(f.repository.load(from: DateTime(2026, 11), to: DateTime(2026, 10)), throwsA(isA<EnrollmentApiException>()));
    expect(f.paths, isEmpty);
  });
  test('institution changing during report invalidates results', () async {
    final f = InstitutionStatisticsFixture()..changeContext = true;
    await expectLater(f.repository.load(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.forbidden)));
  });
  test('missing metrics remain unavailable; malformed counts and totals fail', () async {
    final f = InstitutionStatisticsFixture();
    (f.data['summary'] as Map).remove('student_files');
    expect((await f.repository.load()).summary['student_files'], isNull);
    for (final mode in ['negative', 'duplicate', 'total', 'type']) {
      final x = InstitutionStatisticsFixture();
      final schools = x.data['schools'] as List;
      if (mode == 'negative') (x.data['summary'] as Map)['active_teachers'] = -1;
      if (mode == 'duplicate') schools.add(Map<String, dynamic>.from(schools.single as Map));
      if (mode == 'total') (x.data['summary'] as Map)['attendance_sessions'] = 99;
      if (mode == 'type') (schools.single as Map)['sections'] = '2';
      await expectLater(x.repository.load(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    }
  });
  test('denial is distinct from an empty authorized institution', () async {
    final f = InstitutionStatisticsFixture()..status = 403;
    await expectLater(f.repository.load(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.forbidden)));
    f.status = 200; f.data = {'summary': {'schools': 0, 'attendance_sessions': 0, 'active_enrollments': 0}, 'schools': []};
    expect((await f.repository.load()).schools, isEmpty);
  });
}
