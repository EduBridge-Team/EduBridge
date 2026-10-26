import 'dart:async';

import 'package:edubridge_app/model/institutions/institution_timetable_draft.dart';
import 'package:edubridge_app/screens/institution_timetable/institution_timetable_create_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_timetable_fixture.dart';

TimetableEntryDraft timetableDraft({int year = 10, int section = 30, int subject = 50, int? teacher = 8,
  int day = 2, int period = 2, String? start = '09:00', String? end = '09:45', String? room = 'غرفة جديدة'}) =>
  TimetableEntryDraft(yearId: year, sectionId: section, subjectId: subject, teacherId: teacher,
    weekday: day, period: period, startsAt: start, endsAt: end, room: room);
void main() {
  test('POST database receipt without teacher join is verified by the timetable GET', () async {
    final f = InstitutionTimetableFixture();
    final id = await f.repository.createEntry(timetableDraft());
    expect(id, 81);
    expect(f.creations.single, {'academic_year_id': 10, 'section_id': 30, 'subject_id': 50, 'teacher_id': 8,
      'weekday': 2, 'period_number': 2, 'starts_at': '09:00', 'ends_at': '09:45', 'room': 'غرفة جديدة'});
    expect(f.writes, isEmpty);
    final data = await f.repository.load();
    final created = data.entries.singleWhere((e) => e.id == 81);
    expect(created.teacherName, 'المعلمة سارة');
    expect(created.startsAt, '09:00:00');
  });
  test('nullable teacher, times and room use the real optional API fields', () async {
    final f = InstitutionTimetableFixture();
    await f.repository.createEntry(timetableDraft(teacher: null, start: null, end: null, room: null));
    final row = (await f.repository.load()).entries.singleWhere((e) => e.id == 81);
    expect(row.teacherId, isNull); expect(row.teacherName, isNull); expect(row.startsAt, isNull); expect(row.room, isNull);
  });
  for (final value in [timetableDraft(day: 0), timetableDraft(day: 8), timetableDraft(period: 0),
    timetableDraft(period: 21), timetableDraft(start: '25:00'), timetableDraft(start: '9:00'),
    timetableDraft(start: '09:00', end: '08:00'), timetableDraft(start: '09:00', end: '09:00'),
    timetableDraft(start: null), timetableDraft(room: 'a' * 81)]) {
    test('invalid draft ${value.toJson()} never reaches POST', () async {
      final f = InstitutionTimetableFixture();
      await expectLater(f.repository.createEntry(value), throwsA(isA<EnrollmentApiException>()));
      expect(f.creations, isEmpty);
    });
  }
  for (final kind in ['year', 'section', 'subject', 'teacher', 'inactive-subject', 'context']) {
    test('fresh $kind scope prevents POST', () async {
      final f = InstitutionTimetableFixture();
      final repository = f.repository;
      await repository.loadCreationData();
      var value = timetableDraft();
      switch (kind) {
        case 'year': value = timetableDraft(year: 999); break;
        case 'section': value = timetableDraft(section: 999); break;
        case 'subject': value = timetableDraft(subject: 999); break;
        case 'teacher': f.members.removeWhere((m) => m['id'] == 8); break;
        case 'inactive-subject': (f.academic.data['subjects'] as List).first['is_active'] = false; break;
        case 'context': f.academic.slug = 'other'; break;
      }
      await expectLater(repository.createEntry(value), throwsA(isA<EnrollmentApiException>()));
      expect(f.creations, isEmpty);
    });
  }
  for (final kind in ['section', 'teacher', 'room']) {
    test('$kind slot conflict is checked before POST', () async {
      final f = InstitutionTimetableFixture()..addSection();
      final value = switch (kind) {
        'section' => timetableDraft(period: 1, room: null),
        'teacher' => timetableDraft(section: 31, period: 1, teacher: 7, room: null),
        _ => timetableDraft(section: 31, period: 1, room: 'غرفة نور'),
      };
      await expectLater(f.repository.createEntry(value), throwsA(isA<EnrollmentApiException>()));
      expect(f.creations, isEmpty);
    });
  }
  test('section must belong to the selected year', () async {
    final f = InstitutionTimetableFixture();
    final years = f.academic.data['academic_years'] as List;
    f.academic.data['academic_years'] = [...years,
      <String, dynamic>{...Map<String, dynamic>.from(years.first as Map), 'id': 11, 'is_current': false}];
    await expectLater(f.repository.createEntry(timetableDraft(year: 11)), throwsA(isA<EnrollmentApiException>()));
    expect(f.creations, isEmpty);
  });
  for (final kind in ['receipt', 'unverified', 'denied', 'conflict', 'unexpected-status', 'lost-response', 'verification-denied']) {
    test('$kind never confirms or replays a create', () async {
      final f = InstitutionTimetableFixture();
      final state = InstitutionTimetableCreateController(f.repository);
      addTearDown(state.dispose);
      await state.reload();
      switch (kind) {
        case 'receipt': f.createResponse = {'timetable_entry': {}}; break;
        case 'unverified': f.applyWrite = false; break;
        case 'denied': f.postStatus = 403; break;
        case 'conflict': f.postStatus = 409; break;
        case 'unexpected-status': f.postStatus = 200; break;
        case 'lost-response': f.afterWrite = () => throw Exception('lost response'); break;
        case 'verification-denied': f.afterWrite = () => f.status = 403; break;
      }
      await state.create(timetableDraft());
      expect(state.saved, isFalse);
      expect(state.snapshot, isNull);
      await state.create(timetableDraft());
      expect(f.creations, hasLength(1));
    });
  }
  test('create controller serializes concurrent requests', () async {
    final f = InstitutionTimetableFixture();
    final gate = Completer<void>(); f.beforeWrite = () => gate.future;
    final state = InstitutionTimetableCreateController(f.repository);
    addTearDown(state.dispose);
    await state.reload();
    final pending = state.create(timetableDraft());
    expect(state.busy, isTrue);
    await state.create(timetableDraft(period: 3));
    gate.complete(); await pending;
    expect(f.creations, hasLength(1)); expect(state.saved, isTrue); expect(state.createdId, 81);
  });
}
