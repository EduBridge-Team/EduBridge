import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/screens/institution_specialists/school_specialists_screen.dart';
import 'package:edubridge_app/screens/school_management/school_management_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/school_specialist_assignments_repository.dart';
import 'package:edubridge_app/services/schools/school_management_repository.dart';

import 'curriculum_ui_support.dart';
import 'school_specialists_fixture.dart';

class IndependentStaffFixture {
  bool independent = true;
  bool director = true;
  int schoolId = 2;
  int status = 200;
  final paths = <String>[];
  final posts = <Map<String, dynamic>>[];
  final data = schoolSpecialistJson();

  IndependentStaffFixture() {
    data['organization_id'] = null;
    data['eligible_specialists'] = [
      {'id': 7, 'name': 'مختص موظف', 'role': 'specialist',
        'employment_id': 90, 'employment_school_id': 2, 'employment_active': true},
      {'id': 8, 'name': 'مختص حالي', 'role': 'specialist',
        'employment_id': 91, 'employment_school_id': 2, 'employment_active': true},
    ];
  }

  late final client = EnrollmentApiClient(get: (path) async {
    paths.add(path);
    Object response;
    var code = 200;
    if (path == '/school/context') {
      response = {'school': {
        'id': schoolId, 'name': 'مدرسة مستقلة',
        'organization_id': independent ? null : 4,
      }};
    } else if (path == '/school/delegation') {
      response = {'school': {'id': schoolId, 'name': 'مدرسة مستقلة'},
        'role': director ? 'director' : 'deputy_director',
        'permissions': ['academic']};
    } else if (path == '/school/specialist-assignments') {
      response = data;
      code = status;
    } else {
      throw StateError('Unexpected endpoint $path');
    }
    return http.Response(jsonEncode(response), code,
      headers: {'content-type': 'application/json; charset=utf-8'});
  }, post: (path, body) async {
    paths.add(path);
    posts.add(Map<String, dynamic>.from(body));
    final ending = path.endsWith('/10/end');
    final record = ending ? {
      ...(data['assignments'] as List).first as Map<String, dynamic>,
      'ended_on': '2026-10-29', 'can_end': false,
    } : {
      'id': 11, 'specialist_id': 7, 'specialist_name': 'مختص موظف',
      'starts_on': '2026-10-29', 'ended_on': null, 'can_end': true,
    };
    if (ending) {
      (data['assignments'] as List)[0] = record;
    } else {
      (data['assignments'] as List).add(record);
    }
    data['revision'] = 'r2';
    return http.Response(jsonEncode({
      'organization_id': null, 'school_id': 2, 'assignment': record,
    }), ending ? 200 : 201,
      headers: {'content-type': 'application/json; charset=utf-8'});
  });

  late final specialistRepository = SchoolSpecialistAssignmentsRepository.independent(
    schoolId: 2, client: client);
  late final schoolRepository = SchoolManagementRepository(client: client);
}

void main() {
  test('director assigns only server-confirmed employed specialists at an independent school', () async {
    final f = IndependentStaffFixture();
    final before = await f.specialistRepository.load();
    expect(before.organizationId, isNull);
    expect(before.canAdd(7), isTrue);
    expect(before.canAdd(8), isFalse);
    await f.specialistRepository.assign(before, 7);
    expect(f.posts.single['expected_school_id'], 2);
    expect(f.posts.single['specialist_id'], 7);
    expect(f.paths, contains('/school/specialist-assignments'));
    expect(f.paths, isNot(contains('/children')));
    final latest = await f.specialistRepository.load();
    await f.specialistRepository.end(latest, latest.assignments.firstWhere((a) => a.id == 10));
    expect(f.posts.last['expected_school_id'], 2);
    expect((await f.specialistRepository.load()).assignments.firstWhere((a) => a.id == 10).active, isFalse);
  });

  for (final problem in ['inactive', 'wrong-role', 'foreign-school', 'missing-employment']) {
    test('independent school rejects ineligible specialist: $problem', () async {
      final f = IndependentStaffFixture();
      final eligible = (f.data['eligible_specialists'] as List).first as Map<String, dynamic>;
      if (problem == 'inactive') eligible['employment_active'] = false;
      if (problem == 'wrong-role') eligible['role'] = 'teacher';
      if (problem == 'foreign-school') eligible['employment_school_id'] = 9;
      if (problem == 'missing-employment') eligible.remove('employment_id');
      await expectLater(f.specialistRepository.load(),
        throwsA(isA<EnrollmentApiException>()));
      expect(f.posts, isEmpty);
    });
  }

  for (final problem in ['affiliated-school', 'not-director', 'changed-school']) {
    test('school specialist gateway rejects unauthorized context: $problem', () async {
      final f = IndependentStaffFixture();
      if (problem == 'affiliated-school') f.independent = false;
      if (problem == 'not-director') f.director = false;
      if (problem == 'changed-school') f.schoolId = 3;
      await expectLater(f.specialistRepository.load(),
        throwsA(isA<EnrollmentApiException>()));
      expect(f.paths, isNot(contains('/school/specialist-assignments')));
      expect(f.posts, isEmpty);
    });
  }

  test('stale employment eligibility prevents writes', () async {
    final f = IndependentStaffFixture();
    final before = await f.specialistRepository.load();
    (f.data['eligible_specialists'] as List).removeAt(0);
    f.data['revision'] = 'r2';
    await expectLater(f.specialistRepository.assign(before, 7),
      throwsA(isA<EnrollmentApiException>()));
    expect(f.posts, isEmpty);
  });

  test('missing backend endpoint remains unavailable without fallback', () async {
    final f = IndependentStaffFixture()..status = 404;
    await expectLater(f.specialistRepository.load(), throwsA(isA<EnrollmentApiException>()
      .having((e) => e.failure, 'failure', EnrollmentFailure.unavailable)));
    expect(f.posts, isEmpty);
  });

  testWidgets('independent director sees the specialists action', (tester) async {
    final f = IndependentStaffFixture();
    await tester.pumpWidget(curriculumHost(SchoolManagementScreen(repository: f.schoolRepository), 'ar'));
    await tester.pumpAndSettle();
    expect(find.text('أخصائيو المدرسة'), findsOneWidget);
    await tester.tap(find.text('أخصائيو المدرسة'));
    await tester.pumpAndSettle();
    expect(find.byType(SchoolSpecialistsScreen), findsOneWidget);
    expect(find.textContaining('موظف'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiliated director never sees independent specialist action', (tester) async {
    final f = IndependentStaffFixture()..independent = false;
    await tester.pumpWidget(curriculumHost(SchoolManagementScreen(repository: f.schoolRepository), 'ar'));
    await tester.pumpAndSettle();
    expect(find.text('أخصائيو المدرسة'), findsNothing);
    expect(f.paths, isNot(contains('/school/specialist-assignments')));
  });
}
