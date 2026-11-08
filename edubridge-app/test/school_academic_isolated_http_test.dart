import 'dart:convert';

import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/academic_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

// A12: real Flutter repository -> HTTP -> Laravel -> disposable PostgreSQL 17.
// Disabled for normal local tests. NEVER point this at a deployed environment.
const _run = bool.fromEnvironment('ACADEMIC_STAGING_RUN', defaultValue: false);
const _base = 'http://127.0.0.1:8000/api';
const _syntheticPassword = 'SyntheticAcademicStagingPass!2026';

void main() {
  test('A12 school year/grade/section real HTTP isolated acceptance', () async {
    final client = http.Client();
    addTearDown(client.close);

    Future<String> signIn(String email) async {
      final response = await client.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': _syntheticPassword}),
      );
      expect(response.statusCode, 200, reason: 'Synthetic school login failed');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'];
      expect(token, isA<String>());
      return token as String;
    }

    final schoolAToken = await signIn('synthetic-academic-a@example.test');
    final schoolBToken = await signIn('synthetic-academic-b@example.test');
    final outsiderToken = await signIn('synthetic-academic-outsider@example.test');

    Map<String, String> headers(String token) => {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    Future<http.Response> get(String path, String token) =>
        client.get(Uri.parse('$_base$path'), headers: headers(token));
    Future<http.Response> post(
      String path, Map<String, dynamic> body, String token,
    ) => client.post(
      Uri.parse('$_base$path'),
      headers: headers(token),
      body: jsonEncode(body),
    );
    AcademicRepository schoolRepository(String token) => AcademicRepository(
      client: EnrollmentApiClient(
        get: (path) => get(path, token),
        post: (path, body) => post(path, body, token),
      ),
    );

    final schoolA = schoolRepository(schoolAToken);
    final schoolB = schoolRepository(schoolBToken);
    var catalogA = await schoolA.load();
    var catalogB = await schoolB.load();
    expect(catalogA.school.id, 9301);
    expect(catalogB.school.id, 9302); // Independent school, no institution.
    expect(catalogA.years, isEmpty);
    expect(catalogA.grades, isEmpty);
    expect(catalogA.sections, isEmpty);
    expect(catalogB.years, isEmpty);

    final firstYear = AcademicDraft(
      kind: AcademicKind.year, name: '2026/2027',
      start: DateTime(2026, 9, 1), end: DateTime(2027, 6, 30),
      current: true,
    );
    await schoolA.create(9301, firstYear);
    await schoolA.create(9301, const AcademicDraft(
      kind: AcademicKind.grade, name: 'Grade 2',
    ));
    catalogA = await schoolA.load();
    final yearA = catalogA.years.single;
    final gradeA = catalogA.grades.single;
    expect(yearA.current, isTrue);
    expect(yearA.schoolId, 9301);
    expect(gradeA.schoolId, 9301);

    await schoolA.create(9301, AcademicDraft(
      kind: AcademicKind.section, name: 'A',
      yearId: yearA.id, gradeId: gradeA.id, capacity: 30,
    ));
    catalogA = await schoolA.load();
    expect(catalogA.sections.single.schoolId, 9301);
    expect(catalogA.sections.single.capacity, 30);
    expect(catalogA.sections.single.yearId, yearA.id);
    expect(catalogA.sections.single.gradeId, gradeA.id);

    // Real server must deny stale context assertions and repeated writes.
    await expectLater(
      schoolA.create(9302, const AcademicDraft(
        kind: AcademicKind.grade, name: 'Spoofed Grade',
      )),
      throwsA(isA<EnrollmentApiException>().having(
        (e) => e.failure, 'failure', EnrollmentFailure.validation,
      )),
    );
    await expectLater(
      schoolA.create(9301, const AcademicDraft(
        kind: AcademicKind.grade, name: 'Grade 2',
      )),
      throwsA(isA<EnrollmentApiException>().having(
        (e) => e.failure, 'failure', EnrollmentFailure.conflict,
      )),
    );
    await expectLater(
      schoolA.create(9301, AcademicDraft(
        kind: AcademicKind.section, name: 'A',
        yearId: yearA.id, gradeId: gradeA.id, capacity: 30,
      )),
      throwsA(isA<EnrollmentApiException>().having(
        (e) => e.failure, 'failure', EnrollmentFailure.conflict,
      )),
    );
    final invalidDate = await post('/school/academic/years', {
      'expected_school_id': 9301, 'name': 'Invalid Date',
      'starts_on': '2027-09-01', 'ends_on': '2027-06-30',
      'is_current': true,
    }, schoolAToken);
    expect(invalidDate.statusCode, 422);
    final invalidCapacity = await post('/school/academic/sections', {
      'expected_school_id': 9301, 'name': 'Invalid Capacity',
      'academic_year_id': yearA.id, 'grade_id': gradeA.id, 'capacity': 501,
    }, schoolAToken);
    expect(invalidCapacity.statusCode, 422);

    // Independent school can create its own records but cannot see A's rows.
    await schoolB.create(9302, AcademicDraft(
      kind: AcademicKind.year, name: '2026/2027',
      start: DateTime(2026, 9, 1), end: DateTime(2027, 6, 30),
      current: true,
    ));
    await schoolB.create(9302, const AcademicDraft(
      kind: AcademicKind.grade, name: 'Grade 2',
    ));
    catalogB = await schoolB.load();
    final yearB = catalogB.years.single;
    final gradeB = catalogB.grades.single;
    expect(yearB.schoolId, 9302);
    expect(gradeB.schoolId, 9302);
    expect(catalogB.sections, isEmpty);

    final foreignSection = await post('/school/academic/sections', {
      'expected_school_id': 9301, 'name': 'Foreign',
      'academic_year_id': yearB.id, 'grade_id': gradeB.id, 'capacity': 30,
    }, schoolAToken);
    expect(foreignSection.statusCode, 422);
    expect((await schoolA.load()).sections.length, 1);
    expect((await schoolB.load()).sections, isEmpty);

    // Creating a new current year clears the previous current flag atomically.
    await schoolA.create(9301, AcademicDraft(
      kind: AcademicKind.year, name: '2027/2028',
      start: DateTime(2027, 9, 1), end: DateTime(2028, 6, 30),
      current: true,
    ));
    catalogA = await schoolA.load();
    expect(catalogA.years.length, 2);
    expect(catalogA.years.where((year) => year.current).single.name, '2027/2028');
    expect(catalogA.years.singleWhere((year) => year.id == yearA.id).current, isFalse);
    expect((await schoolB.load()).years.single.current, isTrue);

    final outsiderRead = await get('/school/academic', outsiderToken);
    expect(outsiderRead.statusCode, 403);
    final outsiderWrite = await post('/school/academic/grades', {
      'expected_school_id': 9301, 'name': 'Unauthorized',
    }, outsiderToken);
    expect(outsiderWrite.statusCode, 403);
    final missingToken = await client.get(Uri.parse('$_base/school/academic'));
    expect(missingToken.statusCode, 401);

    // No rejected operation may mutate either school's academic catalog.
    expect((await schoolA.load()).grades.length, 1);
    expect((await schoolB.load()).grades.length, 1);
  }, skip: !_run);
}
