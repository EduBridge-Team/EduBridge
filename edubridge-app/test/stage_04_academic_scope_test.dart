import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/academic_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

http.Response response(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200);

void main() {
  for (final name in ['Wrong school', 'School A']) {
    test('academic catalog must match authenticated school identity: $name',
        () async {
      final calls = <String>[];
      final repository = AcademicRepository(
        client: EnrollmentApiClient(get: (path) async {
          calls.add(path);
          if (path == '/school/context') {
            return response({
              'school': {
                'id': 10,
                'name': 'School A',
                'organization_id': null,
              },
            });
          }
          return response({
            'school': {'id': 10, 'name': name},
            'academic_years': [],
            'grades': [],
            'sections': [],
          });
        }),
      );
      if (name == 'Wrong school') {
        await expectLater(
          repository.load(),
          throwsA(isA<EnrollmentApiException>().having(
              (e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)),
        );
      } else {
        expect((await repository.load()).school.name, 'School A');
      }
      expect(calls, ['/school/context', '/school/academic']);
    });
  }
}
