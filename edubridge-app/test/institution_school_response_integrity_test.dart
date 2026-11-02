import 'package:edubridge_app/services/institution_school_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'institution_school_repository_test.dart' show response;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  for (final payload in [
    {},
    {'schools': null},
    {'schools': {}},
    {
      'schools': [null]
    },
    {
      'schools': [
        {'id': 1, 'name': 'School'},
        'invalid'
      ]
    },
    {
      'schools': [
        {'id': 0, 'name': 'School'}
      ]
    },
    {
      'schools': [
        {'id': '1', 'name': 'School'}
      ]
    },
    {
      'schools': [
        {'id': 1, 'name': ' '}
      ]
    },
    {
      'schools': [
        {'id': 1, 'name': 'A'},
        {'id': 1, 'name': 'B'}
      ]
    },
    {'success': false, 'schools': []},
    {'error': 'Denied', 'schools': []},
  ]) {
    test('malformed school list is not empty success: $payload', () async {
      await http.runWithClient(
        () => expectLater(
            InstitutionSchoolRepository().loadSchools('school-org'),
            throwsA(isA<FormatException>())),
        () => MockClient((_) async => response(payload)),
      );
    });
  }
  test('valid empty school list remains empty', () async {
    await http.runWithClient(() async {
      expect(await InstitutionSchoolRepository().loadSchools('school-org'),
          isEmpty);
    }, () => MockClient((_) async => response({'schools': []})));
  });
  for (final body in ['<html>Unavailable</html>', '[]', 'null', '']) {
    test('invalid success document is rejected for reads and writes: $body',
        () async {
      await http.runWithClient(() async {
        final repository = InstitutionSchoolRepository();
        await expectLater(repository.loadSchools('school-org'),
            throwsA(isA<FormatException>()));
        await expectLater(repository.createSchool('school-org', {'name': 'A'}),
            throwsA(isA<FormatException>()));
        await expectLater(
            repository.updateSchool('school-org', 1, {'name': 'A'}),
            throwsA(isA<FormatException>()));
      }, () => MockClient((_) async => http.Response(body, 200)));
    });
  }
  for (final school in [
    null,
    {},
    {'id': 2, 'name': 'Another school'},
    {'id': 1, 'name': 42}
  ]) {
    test('school detail rejects absent or mismatched record: $school',
        () async {
      await http.runWithClient(
        () => expectLater(
            InstitutionSchoolRepository().loadSchool('school-org', 1),
            throwsA(isA<FormatException>())),
        () => MockClient((_) async => response({'school': school})),
      );
    });
  }
  for (final report in [
    {},
    {'summary': {}},
    {'summary': [], 'schools': []}
  ]) {
    test('missing report cannot unlock management screen: $report', () async {
      await http.runWithClient(
        () => expectLater(
            InstitutionSchoolRepository().loadReport('school-org'),
            throwsA(isA<FormatException>())),
        () => MockClient((_) async => response(report)),
      );
    });
  }
}
