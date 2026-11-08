import 'dart:convert';

import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/school_director_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http';

// Real HTTP against ephemeral Laravel/PostgreSQL on CI, not fake responses.
const _run = bool.fromEnvironment('DIRECTOR_STAGING_RUN', defaultValue: false);
const _base = 'http://127.0.0.1:8000/api';
const _syntheticPassword = 'SyntheticDirectorStagingPass!2026';

void main() {
  test('A03/A04 isolated Flutter repository HTTP integration', () async {
    final client = http.Client();
    addTearDown(client.close);

    Future<String> signIn(String email) async {
      final response = await client.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': _syntheticPassword}),
      );
      expect(response.statusCode, 200, reason: 'Synthetic staging login failed');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['token'] as String;
    }

    final ownerToken = await signIn('synthetic-owner@example.test');
    final previousDirectorToken = await signIn('synthetic-a@example.test');
    final foreignOwnerToken = await signIn('synthetic-foreign@example.test');

    Map<String, String> headers(String token) => {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    Future<http.Response> get(String path, String token) =>
        client.get(Uri.parse('$_base$path'), headers: headers(token));
    Future<http.Response> post(String path, Map<String, dynamic> body, String token) =>
        client.post(Uri.parse('$_base$path'), headers: headers(token), body: jsonEncode(body));
    Future<http.Response> patch(String path, Map<String, dynamic> body, String token) =>
        client.patch(Uri.parse('$_base$path'), headers: headers(token), body: jsonEncode(body));

    final repository = SchoolDirectorRepository(
      client: DirectorApiClient(
        get: (path) => get(path, ownerToken),
        post: (path, data) => post(path, data, ownerToken),
        patch: (path, data) => patch(path, data, ownerToken),
      ),
    );
    final schools = await repository.schools();
    expect(schools.map((s) => s.id).toSet(), {8301, 8302});
    final schoolA = schools.singleWhere((s) => s.id == 8301);
    final schoolB = schools.singleWhere((s) => s.id == 8302);

    // A04: school selection must not reuse another school's data.
    final initialA = await repository.directory(schoolA);
    expect(initialA.current!.directorId, 8401);
    expect(initialA.directors.length, 2);
    final initialB = await repository.directory(schoolB);
    expect(initialB.directors, isEmpty);
    expect(initialB.assignments, isEmpty);
    expect((await repository.directory(schoolA)).current!.directorId, 8401);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // A03: stale state fails; replacement revokes old token.
    await expectLater(
      repository.assign(schoolA, 8402, todayDate, replacesAssignmentId: 99999),
      throwsA(isA<DirectorApiException>().having(
        (e) => e.failure, 'failure', DirectorFailure.conflict,
      )),
    );
    await repository.assign(
      schoolA, 8402, todayDate,
      replacesAssignmentId: initialA.current!.id,
    );
    final afterReplacement = await repository.directory(schoolA);
    expect(afterReplacement.current!.directorId, 8402);
    expect(afterReplacement.assignments.length, 2);
    expect((await get('/me', previousDirectorToken)).statusCode, 401);

    await expectLater(
      repository.assign(schoolA, 8401, todayDate, replacesAssignmentId: initialA.current!.id),
      throwsA(isA<DirectorApiException>().having(
        (e) => e.failure, 'failure', DirectorFailure.conflict,
      )),
    );

    await repository.end(schoolA, afterReplacement.current!, todayDate);
    expect((await repository.directory(schoolA)).current, isNull);
    await expectLater(
      repository.end(schoolA, afterReplacement.current!, todayDate),
      throwsA(isA<DirectorApiException>().having(
        (e) => e.failure, 'failure', DirectorFailure.conflict,
      )),
    );
    expect((await repository.directory(schoolB)).assignments, isEmpty);

    final foreignRead = await get(schoolA.path + '/directors', foreignOwnerToken);
    expect(foreignRead.statusCode, 403);
    final foreignMutation = await post(
      schoolA.path + '/director-assignments',
      {'director_id': 8401, 'starts_on': directorDateString(todayDate),
       'replace_assignment_id': null},
      foreignOwnerToken,
    );
    expect(foreignMutation.statusCode, 403);
  }, skip: !_run);
}
