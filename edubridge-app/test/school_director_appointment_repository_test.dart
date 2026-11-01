import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/school_director_appointment_repository.dart';

const school = DirectorSchool(
  id: 5,
  name: 'School',
  organizationId: 2,
  organizationSlug: 'org',
);

void main() {
  test('loads personal identity from the existing appointment API', () async {
    final repository = SchoolDirectorAppointmentRepository(
      client: DirectorApiClient(
        get: (path) async {
          expect(path, '/admin/schools/5/director');
          return http.Response(
            jsonEncode({
              'school_id': 5,
              'director': {
                'id': 8,
                'name': 'Director',
                'email': 'personal@example.org',
              },
            }),
            200,
          );
        },
      ),
    );
    expect((await repository.current(school))!.email, 'personal@example.org');
  });
  test(
    'appoint posts existing account email and accepts server HTTP 200',
    () async {
      var writes = 0;
      final repository = SchoolDirectorAppointmentRepository(
        client: DirectorApiClient(
          post: (path, body) async {
            writes++;
            expect(path, '/admin/schools/5/director');
            expect(body, {'director_email': 'personal@example.org'});
            return http.Response('{"school_id":5,"director_user_id":8}', 200);
          },
        ),
      );
      await repository.appoint(school, ' Personal@Example.org ');
      expect(writes, 1);
    },
  );
  test(
    'empty director is valid, missing director and foreign scope fail',
    () async {
      for (final data in [
        {'school_id': 5, 'director': null},
        {'school_id': 5},
        {'school_id': 9, 'director': null},
      ]) {
        final repository = SchoolDirectorAppointmentRepository(
          client: DirectorApiClient(
            get: (_) async => http.Response(jsonEncode(data), 200),
          ),
        );
        if (data.containsKey('director') && data['school_id'] == 5) {
          expect(await repository.current(school), isNull);
        } else {
          await expectLater(
            repository.current(school),
            throwsA(isA<DirectorApiException>()),
          );
        }
      }
    },
  );
  test(
    'lost write response is uncertain and never automatically retried',
    () async {
      var writes = 0;
      final repository = SchoolDirectorAppointmentRepository(
        client: DirectorApiClient(
          post: (_, body) async {
            writes++;
            throw Exception('network');
          },
        ),
      );
      await expectLater(
        repository.appoint(school, 'personal@example.org'),
        throwsA(
          isA<DirectorApiException>().having(
            (e) => e.failure,
            'failure',
            DirectorFailure.uncertain,
          ),
        ),
      );
      expect(writes, 1);
    },
  );
}
