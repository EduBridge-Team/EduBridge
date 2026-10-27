import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_teacher_assignments_repository.dart';
import 'package:edubridge_app/screens/institution_teacher_assignments/institution_teacher_assignments_controller.dart';
import 'institution_teacher_assignments_fixture.dart';

void main() {
  test('removal revalidates and confirms absence', () async {
    final f = InstitutionAssignmentsFixture()..addAssignment();
    final repo = f.repository, before = await f.repository.load();
    await repo.remove(before, before.assignments.single);
    expect(f.deletions, ['/institutions/demo-institution/schools/5/academic/teacher-assignments/100']);
    expect((await repo.load()).assignments, isEmpty); expect(f.writes, isEmpty);
  });
  test('foreign school or institution snapshot is rejected before transport', () async {
    final f = InstitutionAssignmentsFixture()..addAssignment();
    final before = await f.repository.load();
    for (final wrongSchool in [true, false]) {
      final repo = InstitutionTeacherAssignmentsRepository(organizationSlug: 'demo-institution',
        organizationId: wrongSchool ? 4 : 99, schoolId: wrongSchool ? 6 : 5,
        client: EnrollmentApiClient(get: (_) async => throw StateError('Must not read'),
          delete: (_) async => throw StateError('Must not delete')));
      await expectLater(repo.remove(before, before.assignments.single), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.validation)));
    }
    expect(f.deletions, isEmpty);
  });
  test('changed or missing assignment cannot be removed', () async {
    for (final missing in [true, false]) {
      final f = InstitutionAssignmentsFixture()..addAssignment();
      final before = await f.repository.load();
      if (missing) { f.assignments.clear(); } else { f.assignments.single['teacher_id'] = 8; }
      await expectLater(f.repository.remove(before, before.assignments.single), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.conflict)));
      expect(f.deletions, isEmpty);
    }
  });
  test('malformed or unverified success never confirms removal', () async {
    for (final malformed in [true, false]) {
      final f = InstitutionAssignmentsFixture()..addAssignment();
      final before = await f.repository.load();
      if (malformed) { f.deleteResponse = {'removed': false}; } else { f.applyRemoval = false; }
      await expectLater(f.repository.remove(before, before.assignments.single), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
      expect(f.deletions, hasLength(1));
    }
  });
  test('denial, lost response and failed verification never replay deletion', () async {
    for (final mode in ['denied', 'lost', 'verify']) {
      final f = InstitutionAssignmentsFixture()..addAssignment();
      final before = await f.repository.load();
      if (mode == 'denied') f.deleteStatus = 403;
      if (mode == 'lost') f.afterDelete = () => throw Exception('Lost response');
      if (mode == 'verify') f.afterDelete = () => f.readStatus = 500;
      await expectLater(f.repository.remove(before, before.assignments.single), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure',
        mode == 'denied' ? EnrollmentFailure.forbidden : EnrollmentFailure.uncertain)));
      expect(f.deletions, hasLength(1));
    }
  });
  test('controller serializes removal; refresh cannot repeat it', () async {
    final f = InstitutionAssignmentsFixture()..addAssignment();
    final gate = Completer<void>(), controller = InstitutionTeacherAssignmentsController(f.repository);
    await controller.reload(); final item = controller.snapshot!.assignments.single;
    f.beforeDelete = () => gate.future;
    final pending = controller.remove(item); await controller.remove(item); gate.complete(); await pending;
    expect(controller.saved, isTrue); expect(controller.snapshot!.assignments, isEmpty);
    await controller.reload(); expect(f.deletions, hasLength(1)); controller.dispose();
  });
}
