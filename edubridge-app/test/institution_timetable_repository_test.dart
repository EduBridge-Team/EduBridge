import 'dart:async';

import 'package:edubridge_app/model/institutions/institution_timetable.dart';
import 'package:edubridge_app/screens/institution_timetable/institution_substitute_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_timetable_fixture.dart';

void main() {
  final monday = DateTime(2026, 10, 26);
  test('API weekdays map Sunday to 1 and Saturday to 7', () {
    expect(institutionWeekday(DateTime(2026, 10, 25)), 1);
    expect(institutionWeekday(monday), 2);
    expect(institutionWeekday(DateTime(2026, 10, 31)), 7);
  });
  test('school-scoped timetable keeps authored names, times and immutable rows', () async {
    final f = InstitutionTimetableFixture();
    final data = await f.repository.load();
    expect(data.entries.single.room, 'غرفة نور');
    expect(data.entries.single.startsAt, '08:00:00');
    expect(data.sectionLabel(30), contains('الصف الثاني'));
    expect(data.nextDate(data.entries.single, DateTime(2026, 10, 27)), DateTime(2026, 11, 2));
    expect(() => data.entries.clear(), throwsUnsupportedError);
  });
  test('GET availability and POST assignment verify the server receipt and exclusion', () async {
    final f = InstitutionTimetableFixture();
    final repository = f.repository;
    final choices = await repository.available(80, monday);
    expect(choices.teachers.keys, [8, 9]);
    final receipt = await repository.assign(choices, 8, 'بديل لهذه الحصة');
    expect(receipt.teacherName, 'المعلمة سارة');
    expect(receipt.date, monday);
    expect(f.writes.single, {'class_date': '2026-10-26', 'substitute_teacher_id': 8, 'notes': 'بديل لهذه الحصة'});
    expect(f.paths, contains('/institutions/demo-institution/schools/5/timetable/80/substitutions'));
    expect((await repository.available(80, monday)).teachers.containsKey(8), isFalse);
  });
  for (final kind in ['school', 'section', 'year', 'subject', 'day', 'period', 'time', 'duplicate', 'organization']) {
    test('rejects $kind timetable data', () async {
      final f = InstitutionTimetableFixture();
      switch (kind) {
        case 'school': f.rows.first['school_id'] = 999; break;
        case 'section': f.rows.first['section_id'] = 999; break;
        case 'year': f.rows.first['academic_year_id'] = 999; break;
        case 'subject': f.rows.first['subject_id'] = 999; break;
        case 'day': f.rows.first['weekday'] = 0; break;
        case 'period': f.rows.first['period_number'] = 21; break;
        case 'time': f.rows.first['starts_at'] = '25:01'; break;
        case 'duplicate': f.rows.add(Map<String, dynamic>.from(f.rows.first)); break;
        case 'organization': f.academic.slug = 'other'; break;
      }
      await expectLater(f.repository.load(), throwsA(isA<EnrollmentApiException>()));
    });
  }
  for (final kind in ['original', 'foreign', 'duplicate']) {
    test('rejects $kind available teacher', () async {
      final f = InstitutionTimetableFixture();
      switch (kind) {
        case 'original': f.candidates = [Map<String, dynamic>.from(f.members.first)]; break;
        case 'foreign': f.candidates.first['id'] = 999; break;
        case 'duplicate': f.candidates.add(Map<String, dynamic>.from(f.candidates.first)); break;
      }
      await expectLater(f.repository.available(80, monday), throwsA(isA<EnrollmentApiException>()));
    });
  }
  test('wrong weekday, year date or entry never requests availability', () async {
    for (final date in [DateTime(2026, 10, 27), DateTime(2028, 10, 30)]) {
      final f = InstitutionTimetableFixture();
      await expectLater(f.repository.available(80, date), throwsA(isA<EnrollmentApiException>()));
      expect(f.paths.any((p) => p.contains('available-substitutes')), isFalse);
    }
    final f = InstitutionTimetableFixture();
    await expectLater(f.repository.available(999, monday), throwsA(isA<EnrollmentApiException>()));
  });
  for (final kind in ['teacher-unavailable', 'slot-changed', 'long-note', 'context']) {
    test('$kind prevents substitution POST', () async {
      final f = InstitutionTimetableFixture();
      final repository = f.repository;
      final choices = await repository.available(80, monday);
      String? notes;
      switch (kind) {
        case 'teacher-unavailable': f.assignedTeacher = 8; break;
        case 'slot-changed': f.rows.first['period_number'] = 2; break;
        case 'long-note': notes = 'a' * 2001; break;
        case 'context': f.academic.slug = 'other'; break;
      }
      await expectLater(repository.assign(choices, 8, notes), throwsA(isA<EnrollmentApiException>()));
      expect(f.writes, isEmpty);
    });
  }
  for (final kind in ['receipt', 'unverified', 'denied', 'conflict', 'lost-response', 'verification-denied']) {
    test('$kind never confirms or repeats an assignment', () async {
      final f = InstitutionTimetableFixture();
      final state = InstitutionSubstituteController(f.repository, 80, monday);
      addTearDown(state.dispose);
      await state.reload();
      switch (kind) {
        case 'receipt': f.response = {'substitution': {'id': 90, 'timetable_entry_id': 999}}; break;
        case 'unverified': f.applyWrite = false; break;
        case 'denied': f.postStatus = 403; break;
        case 'conflict': f.postStatus = 409; break;
        case 'lost-response': f.afterWrite = () => throw Exception('lost response'); break;
        case 'verification-denied': f.afterWrite = () => f.status = 403; break;
      }
      await state.assign(8, null);
      expect(state.saved, isFalse);
      expect(state.snapshot, isNull);
      await state.assign(8, null);
      expect(f.writes, hasLength(1));
    });
  }
  test('concurrent assignment taps are serialized', () async {
    final f = InstitutionTimetableFixture();
    final gate = Completer<void>();
    f.beforeWrite = () => gate.future;
    final state = InstitutionSubstituteController(f.repository, 80, monday);
    addTearDown(state.dispose);
    await state.reload();
    final first = state.assign(8, null);
    expect(state.busy, isTrue);
    await state.assign(9, null);
    gate.complete(); await first;
    expect(f.writes, hasLength(1));
    expect(state.saved, isTrue);
  });
}
