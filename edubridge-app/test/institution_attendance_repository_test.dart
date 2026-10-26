import 'package:edubridge_app/model/institutions/institution_attendance.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_attendance_fixture.dart';

void main() {
  test('scoped session and student details use existing GET contracts', () async {
    final f = InstitutionAttendanceFixture();
    final data = await f.repository.load(sessionId: 60, date: DateTime(2026, 10, 26));
    expect(data.session!.id, 60);
    expect(data.records.map((r) => r.status), [InstitutionAttendanceStatus.present, InstitutionAttendanceStatus.absent]);
    expect(data.records.last.note, 'عذر مكتوب');
    expect(data.sectionLabel(data.session!), contains('الصف الثاني'));
    expect(data.subjectLabel(data.session!), 'اللغة العربية');
    expect(f.paths, contains('/institutions/demo-institution/schools/5/attendance?date=2026-10-26'));
    expect(f.paths.last, '/institutions/demo-institution/schools/5/attendance/60');
    expect(() => data.records.clear(), throwsUnsupportedError);
    expect(() => data.sessions.clear(), throwsUnsupportedError);
  });
  test('date filter handles empty sessions without fabricating students', () async {
    final f = InstitutionAttendanceFixture();
    expect((await f.repository.load(date: DateTime(2026, 10, 25))).sessions, isEmpty);
    expect((await f.repository.load()).records, isEmpty);
  });
  test('closed, daily and subjectless sessions retain nullable fields', () async {
    final f = InstitutionAttendanceFixture();
    f.sessions.first.addAll({'subject_id': null, 'period_number': null, 'notes': null, 'status': 'closed'});
    final data = await f.repository.load(sessionId: 60);
    expect(data.session!.closed, isTrue);
    expect(data.session!.period, isNull);
    expect(data.subjectLabel(data.session!), isNull);
  });
  for (final kind in ['section', 'subject', 'duplicate', 'date', 'period', 'status', 'filter', 'organization']) {
    test('rejects $kind catalog', () async {
      final f = InstitutionAttendanceFixture();
      DateTime? date;
      switch (kind) {
        case 'section': f.sessions.first['section_id'] = 999; break;
        case 'subject': f.sessions.first['subject_id'] = 999; break;
        case 'duplicate': f.sessions.add(Map<String, dynamic>.from(f.sessions.first)); break;
        case 'date': f.sessions.first['attendance_date'] = '2026-02-30'; break;
        case 'period': f.sessions.first['period_number'] = 21; break;
        case 'status': f.sessions.first['status'] = 'unknown'; break;
        case 'filter': f.filterDates = false; date = DateTime(2026, 10, 25); break;
        case 'organization': f.academic.slug = 'other'; break;
      }
      await expectLater(f.repository.load(date: date), throwsA(isA<EnrollmentApiException>()));
    });
  }
  for (final kind in ['session', 'identity', 'duplicate-child', 'duplicate-record', 'status']) {
    test('rejects $kind details', () async {
      final f = InstitutionAttendanceFixture();
      switch (kind) {
        case 'session': f.records.first['attendance_session_id'] = 99; break;
        case 'identity': f.detailSession = {...f.sessions.first, 'id': 99}; break;
        case 'duplicate-child': f.records.last['child_id'] = 9; break;
        case 'duplicate-record': f.records.last['id'] = 70; break;
        case 'status': f.records.first['status'] = 'unknown'; break;
      }
      await expectLater(f.repository.load(sessionId: 60), throwsA(isA<EnrollmentApiException>()));
    });
  }
  test('foreign session is rejected before the detail GET', () async {
    final f = InstitutionAttendanceFixture();
    await expectLater(f.repository.load(sessionId: 999), throwsA(isA<EnrollmentApiException>()));
    expect(f.paths.any((p) => p.endsWith('/999')), isFalse);
  });
  test('pinned organization id must still match', () async {
    final f = InstitutionAttendanceFixture();
    final repository = InstitutionAttendanceRepository(organizationSlug: 'demo-institution',
      organizationId: 99, schoolId: 5, client: EnrollmentApiClient(get: f.academic.get));
    await expectLater(repository.load(), throwsA(isA<EnrollmentApiException>()));
  });
  for (final status in [401, 403, 404, 500]) {
    test('HTTP $status stays an error, not an empty attendance result', () async {
      final f = InstitutionAttendanceFixture()..status = status;
      await expectLater(f.repository.load(), throwsA(isA<EnrollmentApiException>()));
    });
  }
}
