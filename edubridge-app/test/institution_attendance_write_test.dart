import 'dart:async';

import 'package:edubridge_app/model/institutions/institution_attendance.dart';
import 'package:edubridge_app/model/institutions/institution_attendance_draft.dart';
import 'package:edubridge_app/screens/institution_attendance/institution_attendance_write_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_attendance_fixture.dart';

AttendanceSessionDraft draft({int section = 30, int? subject, int? period = 2}) =>
  AttendanceSessionDraft(sectionId: section, subjectId: subject, period: period, date: DateTime(2026, 10, 26), note: 'نص الجلسة');
Map<int, AttendanceMark> marks() => {
  9: AttendanceMark(InstitutionAttendanceStatus.late, 'تأخر بسيط'),
  8: AttendanceMark(InstitutionAttendanceStatus.excused, ''),
};
void main() {
  test('creates a scoped session and verifies initialized students', () async {
    final f = InstitutionAttendanceFixture();
    final id = await f.repository.createAttendance(draft(subject: 50));
    expect(id, 61);
    expect(f.posts.single, {'section_id': 30, 'subject_id': 50, 'attendance_date': '2026-10-26',
      'period_number': 2, 'notes': 'نص الجلسة'});
    expect((await f.repository.load(sessionId: id)).records, hasLength(2));
  });
  for (final kind in ['section', 'subject', 'period', 'duplicate', 'inactive-subject']) {
    test('invalid $kind never creates a session', () async {
      final f = InstitutionAttendanceFixture();
      AttendanceSessionDraft value = draft();
      switch (kind) {
        case 'section': value = draft(section: 999); break;
        case 'subject': value = draft(subject: 999); break;
        case 'period': value = draft(period: 21); break;
        case 'duplicate': value = draft(period: 1); break;
        case 'inactive-subject':
          (f.academic.data['subjects'] as List).first['is_active'] = false;
          value = draft(subject: 50); break;
      }
      await expectLater(f.repository.createAttendance(value), throwsA(isA<EnrollmentApiException>()));
      expect(f.posts, isEmpty);
    });
  }
  for (final kind in ['acknowledgement', 'unverified', 'lost-response']) {
    test('does not confirm $kind creation', () async {
      final f = InstitutionAttendanceFixture();
      switch (kind) {
        case 'acknowledgement': f.createResponse = {}; break;
        case 'unverified': f.applyWrites = false; break;
        case 'lost-response': f.afterWrite = () => throw Exception('lost response'); break;
      }
      await expectLater(f.repository.createAttendance(draft()), throwsA(isA<EnrollmentApiException>()));
      expect(f.posts, hasLength(1));
    });
  }
  test('saves statuses and notes then closes the same session', () async {
    final f = InstitutionAttendanceFixture();
    final repository = f.repository;
    final expected = await repository.loadEditor(sessionId: 60, date: DateTime(2026, 10, 26));
    await repository.saveAttendance(expected, marks(), closeSession: true);
    expect(f.puts.single['close_session'], isTrue);
    expect((f.puts.single['records'] as List).last['note'], isNull);
    final after = await repository.load(sessionId: 60);
    expect(after.session!.closed, isTrue);
    expect(after.records.first.status, InstitutionAttendanceStatus.late);
    expect(after.records.first.note, 'تأخر بسيط');
  });
  for (final kind in ['closed', 'roster', 'concurrent-edit', 'foreign-child', 'long-note', 'context']) {
    test('rejects $kind before PUT', () async {
      final f = InstitutionAttendanceFixture();
      final repository = f.repository;
      final expected = await repository.loadEditor(sessionId: 60, date: DateTime(2026, 10, 26));
      final values = marks();
      switch (kind) {
        case 'closed': f.sessions.first['status'] = 'closed'; break;
        case 'roster': f.enrollments.first['status'] = 'withdrawn'; break;
        case 'concurrent-edit': f.records.first['status'] = 'absent'; break;
        case 'foreign-child': values[99] = const AttendanceMark(InstitutionAttendanceStatus.present, null); break;
        case 'long-note': values[9] = AttendanceMark(InstitutionAttendanceStatus.present, 'a' * 1001); break;
        case 'context': f.academic.slug = 'other'; break;
      }
      await expectLater(repository.saveAttendance(expected, values, closeSession: false), throwsA(isA<EnrollmentApiException>()));
      expect(f.puts, isEmpty);
    });
  }
  test('editor rejects duplicate or unknown attendance student records', () async {
    for (final mode in ['duplicate', 'unknown']) {
      final f = InstitutionAttendanceFixture();
      if (mode == 'duplicate') {
        f.records.add({...f.records.first, 'id': 99});
      } else {
        f.records.add({...f.records.first, 'id': 99, 'child_id': 999});
      }
      await expectLater(
        f.repository.loadEditor(sessionId: 60, date: DateTime(2026, 10, 26)),
        throwsA(isA<EnrollmentApiException>().having(
          (e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)),
      );
      expect(f.puts, isEmpty);
    }
  });
  test('editor excludes withdrawn students and retains session records for history', () async {
    final f = InstitutionAttendanceFixture();
    f.enrollments.first['status'] = 'withdrawn';
    final data = await f.repository.loadEditor(sessionId: 60, date: DateTime(2026, 10, 26));
    expect(data.students.map((s) => s.id), [8]);
    expect(data.view.records, hasLength(2));
  });
  for (final kind in ['acknowledgement', 'unverified', 'denied', 'conflict', 'lost-response', 'verification-denied']) {
    test('save $kind never confirms or replays', () async {
      final f = InstitutionAttendanceFixture();
      final controller = AttendanceMarkController(f.repository, 60, DateTime(2026, 10, 26));
      addTearDown(controller.dispose);
      await controller.reload();
      final expected = controller.snapshot!;
      switch (kind) {
        case 'acknowledgement': f.saveResponse = {}; break;
        case 'unverified': f.applyWrites = false; break;
        case 'denied': f.putStatus = 403; break;
        case 'conflict': f.putStatus = 409; break;
        case 'lost-response': f.afterWrite = () => throw Exception('lost response'); break;
        case 'verification-denied': f.afterWrite = () => f.status = 403; break;
      }
      await controller.save(expected, marks(), false);
      expect(controller.saved, isFalse);
      expect(controller.snapshot, isNull);
      await controller.save(expected, marks(), false);
      expect(f.puts, hasLength(1));
    });
  }
  test('concurrent save requests are serialized', () async {
    final f = InstitutionAttendanceFixture();
    final gate = Completer<void>();
    f.beforeWrite = () => gate.future;
    final controller = AttendanceMarkController(f.repository, 60, DateTime(2026, 10, 26));
    addTearDown(controller.dispose);
    await controller.reload();
    final expected = controller.snapshot!;
    final pending = controller.save(expected, marks(), false);
    expect(controller.busy, isTrue);
    await controller.save(expected, marks(), false);
    gate.complete(); await pending;
    expect(f.puts, hasLength(1));
    expect(controller.saved, isTrue);
  });
}
