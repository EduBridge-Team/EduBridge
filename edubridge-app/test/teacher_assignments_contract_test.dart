import 'dart:async';

import 'package:edubridge_app/model/schools/teacher_assignment.dart';
import 'package:edubridge_app/model/schools/teacher_assignments_catalog.dart';
import 'package:edubridge_app/screens/teacher_assignments/teacher_assignments_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'teacher_assignments_http_fixture.dart';

void main() {
  test('catalog validates school relations and keeps lists immutable', () {
    final data = TeacherAssignmentsCatalog.fromJson(assignmentsPayload());
    expect(data.sectionLabel(3), contains('2026/2027'));
    expect(() => data.assignments.clear(), throwsUnsupportedError);
    expect(() => data.teachers.clear(), throwsUnsupportedError);
    expect(() => data.subjects.clear(), throwsUnsupportedError);
    expect(data.canCreate(newTeacherAssignment), isTrue);
    expect(
      data.canCreate(
        const TeacherAssignmentDraft(teacherId: 20, sectionId: 3, subjectId: 8),
      ),
      isFalse,
    );
    expect(
      data.canCreate(
        const TeacherAssignmentDraft(teacherId: 21, sectionId: 3, subjectId: 8),
      ),
      isFalse,
    );
    expect(
      data.canCreate(
        const TeacherAssignmentDraft(teacherId: 22, sectionId: 3, subjectId: 9),
      ),
      isFalse,
    );
  });
  final invalid = <String, Map<String, dynamic>>{
    'missing teachers': assignmentsPayload()..remove('teachers'),
    'foreign teacher': {
      ...assignmentsPayload(),
      'teachers': [
        {
          'id': 20,
          'school_id': 99,
          'role': 'teacher',
          'name': 'Other',
          'is_active': true,
        },
      ],
    },
    'wrong role': {
      ...assignmentsPayload(),
      'teachers': [
        {
          'id': 20,
          'school_id': 10,
          'role': 'parent',
          'name': 'Other',
          'is_active': true,
        },
      ],
    },
    'invalid active': {
      ...assignmentsPayload(),
      'teachers': [
        {
          'id': 20,
          'school_id': 10,
          'role': 'teacher',
          'name': 'Other',
          'is_active': 1,
        },
      ],
    },
    'missing teacher': {...assignmentsPayload(), 'teachers': []},
    'missing subject': {...assignmentsPayload(), 'subjects': []},
    'foreign section': {
      ...assignmentsPayload(),
      'assignments': [
        {...assignmentJson(), 'section_id': 99},
      ],
    },
    'foreign school': {
      ...assignmentsPayload(),
      'assignments': [
        {...assignmentJson(), 'school_id': 99},
      ],
    },
    'duplicate identity': {
      ...assignmentsPayload(),
      'assignments': [assignmentJson(), assignmentJson(id: 51)],
    },
    'duplicate id': {
      ...assignmentsPayload(),
      'assignments': [assignmentJson(), assignmentJson(teacher: 22)],
    },
    'invalid version': {
      ...assignmentsPayload(),
      'assignments': [assignmentJson(version: 0)],
    },
  };
  for (final entry in invalid.entries) {
    test(
      'rejects ${entry.key}',
      () => expect(
        () => TeacherAssignmentsCatalog.fromJson(entry.value),
        throwsFormatException,
      ),
    );
  }
  test('context school must match catalog', () async {
    final fixture = TeacherAssignmentsHttpFixture()..contextSchool = 99;
    await expectLater(
      fixture.repository.load(),
      throwsA(isA<EnrollmentApiException>()),
    );
  });
  test(
    'create and remove send scoped/versioned payloads and validate receipts',
    () async {
      final fixture = TeacherAssignmentsHttpFixture();
      await fixture.repository.create(10, newTeacherAssignment);
      expect(fixture.writes.first, {
        'path': '/school/teacher-assignments',
        'expected_school_id': 10,
        ...newTeacherAssignment.toJson(),
      });
      final item = (await fixture.repository.load()).assignments.singleWhere(
        (v) => v.id == 51,
      );
      await fixture.repository.remove(item);
      expect(fixture.writes.last, {
        'path': '/school/teacher-assignments/51/remove',
        'expected_school_id': 10,
        'expected_version': 1,
      });
      expect((await fixture.repository.load()).assignments.map((v) => v.id), [
        50,
      ]);
    },
  );
  for (final remove in [false, true]) {
    test(
      '${remove ? 'removal' : 'creation'} mismatched receipt blocks repeat writes',
      () async {
        final fixture = TeacherAssignmentsHttpFixture()..badReceipt = true;
        final controller = TeacherAssignmentsController(fixture.repository);
        addTearDown(controller.dispose);
        await controller.reload();
        if (remove) {
          await controller.remove(controller.snapshot!.assignments.single);
        } else {
          await controller.create(newTeacherAssignment);
        }
        expect(controller.error, EnrollmentFailure.invalidResponse);
        expect(controller.snapshot, isNull);
        expect(await controller.create(newTeacherAssignment), isFalse);
        expect(fixture.writes.length, 1);
      },
    );
  }
  test(
    'duplicate/ineligible/foreign drafts and stale removal never write',
    () async {
      final fixture = TeacherAssignmentsHttpFixture();
      final controller = TeacherAssignmentsController(fixture.repository);
      addTearDown(controller.dispose);
      await controller.reload();
      for (final draft in [
        const TeacherAssignmentDraft(teacherId: 20, sectionId: 3, subjectId: 8),
        const TeacherAssignmentDraft(teacherId: 21, sectionId: 3, subjectId: 8),
        const TeacherAssignmentDraft(teacherId: 22, sectionId: 3, subjectId: 9),
        const TeacherAssignmentDraft(
          teacherId: 22,
          sectionId: 99,
          subjectId: 8,
        ),
      ]) {
        expect(await controller.create(draft), isFalse);
      }
      await controller.remove(const TeacherAssignment(50, 10, 20, 3, 8, 2));
      await controller.remove(const TeacherAssignment(50, 99, 20, 3, 8, 1));
      expect(fixture.writes, isEmpty);
    },
  );
  test(
    'writes serialize; confirmed save with failed refresh is never replayed',
    () async {
      final fixture = TeacherAssignmentsHttpFixture()
        ..pending = Completer<void>()
        ..failAfterWrite = true;
      final controller = TeacherAssignmentsController(fixture.repository);
      addTearDown(controller.dispose);
      await controller.reload();
      final saved = controller.create(newTeacherAssignment);
      await controller.create(newTeacherAssignment);
      await controller.remove(controller.snapshot!.assignments.single);
      expect(fixture.writes.length, 1);
      fixture.pending!.complete();
      expect(await saved, isTrue);
      expect(controller.saved, isTrue);
      expect(controller.error, EnrollmentFailure.unavailable);
      expect(controller.snapshot, isNull);
      expect(await controller.create(newTeacherAssignment), isFalse);
    },
  );
}
