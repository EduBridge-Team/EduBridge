import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/specialist_schools/specialist_school_students_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'specialist_school_students_fixture.dart';

void main() {
  test('directory and roster are immutable; explicit scoped follow confirms receipt and roster', () async {
    final f = SpecialistSchoolStudentsFixture(), repo = f.repository;
    final directory = await repo.schools(), school = directory.schools.first;
    final roster = await repo.students(directory.specialistId, school);
    expect(() => directory.schools.clear(), throwsUnsupportedError);
    expect(() => roster.students.clear(), throwsUnsupportedError);
    expect(f.posts, isEmpty);
    await repo.follow(roster, roster.students.first);
    expect(f.posts.single.keys, unorderedEquals([
      'expected_revision', 'expected_assignment_id', 'expected_enrollment_id',
      'expected_case_limit', 'expected_selected_cases', 'idempotency_key']));
    expect(f.posts.single['expected_assignment_id'], 10);
    expect(f.posts.single['expected_enrollment_id'], 200);
    expect(f.posts.single['idempotency_key'], matches(RegExp(r'^[0-9a-f]{32}$')));
    final after = await repo.students(7, school);
    expect(after.students.first.following, isTrue); expect(after.students.first.followupId, 999);
    expect(f.paths.where((p) => p == '/children'), isEmpty);
  });
  for (final field in ['specialist_id', 'organization_id', 'school_id', 'assignment_id']) {
    test('rejects foreign roster $field', () async {
      final f = SpecialistSchoolStudentsFixture(), schools = await f.repository.schools();
      f.rosters[2]![field] = 1000;
      await expectLater(f.repository.students(7, schools.schools.first), throwsA(isA<EnrollmentApiException>()));
    });
  }
  for (final issue in ['duplicate-child', 'duplicate-enrollment', 'following-id', 'following-capability', 'partial']) {
    test('rejects malformed roster $issue', () async {
      final f = SpecialistSchoolStudentsFixture(), schools = await f.repository.schools();
      final data = f.rosters[2]!, rows = data['students'] as List;
      if (issue == 'duplicate-child') rows.last['child_id'] = rows.first['child_id'];
      if (issue == 'duplicate-enrollment') rows.last['enrollment_id'] = rows.first['enrollment_id'];
      if (issue == 'following-id') rows.last['followup_id'] = null;
      if (issue == 'following-capability') rows.last['can_follow'] = true;
      if (issue == 'partial') data['complete'] = false;
      await expectLater(f.repository.students(7, schools.schools.first), throwsA(isA<EnrollmentApiException>()));
    });
  }
  for (final issue in ['revision', 'enrollment', 'capability', 'actor']) {
    test('preflight prevents stale $issue from writing', () async {
      final f = SpecialistSchoolStudentsFixture(), schools = await f.repository.schools();
      final roster = await f.repository.students(7, schools.schools.first);
      if (issue == 'revision') f.rosters[2]!['revision'] = 'r2';
      if (issue == 'enrollment') (f.rosters[2]!['students'] as List).first['enrollment_id'] = 999;
      if (issue == 'capability') (f.rosters[2]!['students'] as List).first['can_follow'] = false;
      if (issue == 'actor') f.userId = 8;
      await expectLater(f.repository.follow(roster, roster.students.first), throwsA(isA<EnrollmentApiException>()));
      expect(f.posts, isEmpty);
    });
  }
  for (final issue in ['receipt', 'readback', 'no-record']) {
    test('unverified follow-up cannot be confirmed or replayed $issue', () async {
      final f = SpecialistSchoolStudentsFixture(), directory = await f.repository.schools();
      final state = SpecialistSchoolStudentsController(f.repository, 7, directory.schools.first);
      await state.reload(); final expected = state.snapshot!, student = state.snapshot!.students.first;
      f.badReceipt = issue == 'receipt'; f.failAfter = issue == 'readback'; f.skipPersistence = issue == 'no-record';
      await state.follow(expected, student);
      expect(state.saved, isFalse); expect(state.snapshot, isNull);
      await state.follow(expected, student); expect(f.posts, hasLength(1));
      state.dispose();
    });
  }
  test('changing role or identity after roster response never returns data', () async {
    final f = SpecialistSchoolStudentsFixture(), directory = await f.repository.schools();
    f.afterRoster = () => f.role = 'teacher';
    await expectLater(f.repository.students(7, directory.schools.first),
      throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.forbidden)));
  });
  test('unsupported school API never loads global children', () async {
    final f = SpecialistSchoolStudentsFixture()..status = 404;
    await expectLater(f.repository.schools(), throwsA(isA<EnrollmentApiException>()));
    expect(f.posts, isEmpty); expect(f.paths, isNot(contains('/children')));
  });
}

