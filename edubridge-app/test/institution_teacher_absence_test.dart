import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/screens/institution_timetable/institution_teacher_absence_controller.dart';
import 'institution_timetable_fixture.dart';

void main() {
  final date = DateTime(2026, 10, 26);
  test('confirmed absence validates receipt and affected slots', () async {
    final f = InstitutionTimetableFixture();
    final receipt = await f.repository.reportAbsence(7, date, 'سبب');
    expect(receipt.id, 100); expect(receipt.teacherId, 7);
    expect(receipt.affected.single.id, 80); expect(receipt.date, date);
    expect(f.absences.single, {'teacher_id': 7, 'absence_date': '2026-10-26', 'reason': 'سبب'});
    expect((await f.repository.reportAbsence(8, date, null)).affected, isEmpty);
  });
  test('invalid choices and reasons do not write', () async {
    final f = InstitutionTimetableFixture();
    for (final id in [0, 999]) {
      await expectLater(f.repository.reportAbsence(id, date, null), throwsA(isA<EnrollmentApiException>()));
    }
    await expectLater(f.repository.reportAbsence(7, date, 'x' * 2001), throwsA(isA<EnrollmentApiException>()));
    expect(f.absences, isEmpty);
  });
  test('foreign or malformed receipts never confirm success', () async {
    for (final change in <String, dynamic>{'school_id': 9, 'teacher_id': 8,
      'absence_date': '2026-10-27', 'status': 'pending', 'reason': 'wrong'}.entries) {
      final f = InstitutionTimetableFixture();
      f.absenceResponse = {'absence': {'id': 100, 'school_id': 5, 'teacher_id': 7,
        'absence_date': '2026-10-26', 'status': 'confirmed', 'reason': null, change.key: change.value}, 'affected_classes': []};
      await expectLater(f.repository.reportAbsence(7, date, null), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    }
  });
  test('inconsistent affected classes never confirm success', () async {
    for (final mode in ['missing', 'duplicate', 'foreign', 'weekday']) {
      final f = InstitutionTimetableFixture();
      final row = Map<String, dynamic>.from(f.rows.single);
      if (mode == 'foreign') row['school_id'] = 6;
      if (mode == 'weekday') row['weekday'] = 3;
      f.absenceResponse = {'absence': {'id': 100, 'school_id': 5, 'teacher_id': 7,
        'absence_date': '2026-10-26', 'status': 'confirmed', 'reason': null},
        'affected_classes': mode == 'missing' ? [] : [row, if (mode == 'duplicate') row]};
      await expectLater(f.repository.reportAbsence(7, date, null), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    }
  });
  test('lost response and denial never replay a write', () async {
    for (final lost in [false, true]) {
      final f = InstitutionTimetableFixture();
      if (lost) { f.afterWrite = () => throw Exception('lost'); } else { f.postStatus = 403; }
      await expectLater(f.repository.reportAbsence(7, date, null), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', lost ? EnrollmentFailure.uncertain : EnrollmentFailure.forbidden)));
      expect(f.absences, hasLength(1));
    }
  });
  test('concurrent reports serialize and resume only reads', () async {
    final f = InstitutionTimetableFixture(), gate = Completer<void>();
    final c = InstitutionTeacherAbsenceController(f.repository); await c.reload();
    f.beforeWrite = () => gate.future;
    final pending = c.report(7, date, null); await c.report(7, date, null);
    gate.complete(); await pending; expect(c.saved, isTrue); expect(c.receipt, isNotNull);
    await c.reload(); expect(f.absences, hasLength(1)); c.dispose();
  });
}
