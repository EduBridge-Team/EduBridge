import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/school_director_repository.dart';

const school = DirectorSchool(
  id: 10,
  name: 'School',
  organizationId: 4,
  organizationSlug: 'demo-institution',
);
const draft = DirectorDraft(
  name: ' Noor ',
  email: ' director@example.org ',
  phone: ' 123 ',
  qualification: ' Education ',
  experienceYears: 5,
);
Map<String, dynamic> profile({int schoolId = 10}) => {
  'id': 30,
  'school_id': schoolId,
  'name': 'Noor',
  'email': 'director@example.org',
  'phone': '123',
  'qualification': 'Education',
  'experience_years': 5,
};
Map<String, dynamic> assignment({int schoolId = 10, String? endedOn}) => {
  'id': 50,
  'school_id': schoolId,
  'director_id': 30,
  'starts_on': '2026-10-01',
  'ended_on': endedOn,
};
Map<String, dynamic> directory() => {
  'school_id': 10,
  'directors': [profile()],
  'assignments': [assignment()],
};
http.Response json(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status);
Matcher failure(DirectorFailure value) => throwsA(
  isA<DirectorApiException>().having((e) => e.failure, 'failure', value),
);

void main() {
  test(
    'schools resolve authenticated context and retain institution scope',
    () async {
      final calls = <String>[];
      final repository = SchoolDirectorRepository(
        client: DirectorApiClient(
          get: (path) async {
            calls.add(path);
            return path.endsWith('my-organization')
                ? json({
                    'organization': {'id': 4, 'slug': 'demo-institution'},
                  })
                : json({
                    'schools': [
                      {'id': 10, 'organization_id': 4, 'name': 'School'},
                    ],
                  });
          },
        ),
      );
      final schools = await repository.schools();
      expect(calls, [
        '/institutions/my-organization',
        '/institutions/demo-institution/schools',
      ]);
      expect(schools.single.path, school.path);
    },
  );

  for (final invalid in [
    {'id': 4, 'slug': '../foreign'},
    {'id': 0, 'slug': 'demo-institution'},
    {'slug': 'demo-institution'},
  ]) {
    test(
      'invalid institution context cannot request a school directory: $invalid',
      () async {
        var calls = 0;
        final repository = SchoolDirectorRepository(
          client: DirectorApiClient(
            get: (path) async {
              calls++;
              return json({'organization': invalid});
            },
          ),
        );
        await expectLater(
          repository.schools(),
          failure(DirectorFailure.invalidResponse),
        );
        expect(calls, 1);
      },
    );
  }

  test('foreign schools are rejected', () async {
    final repository = SchoolDirectorRepository(
      client: DirectorApiClient(
        get: (path) async => path.endsWith('my-organization')
            ? json({
                'organization': {'id': 4, 'slug': 'demo-institution'},
              })
            : json({
                'schools': [
                  {'id': 10, 'organization_id': 9, 'name': 'School'},
                ],
              }),
      ),
    );
    await expectLater(
      repository.schools(),
      failure(DirectorFailure.invalidResponse),
    );
  });

  test(
    'directory reads only school-scoped endpoint and preserves history',
    () async {
      final repository = SchoolDirectorRepository(
        client: DirectorApiClient(
          get: (path) async {
            expect(path, '${school.path}/directors');
            return json(directory());
          },
        ),
      );
      final result = await repository.directory(school);
      expect(result.current!.directorId, 30);
      expect(result.directors.single.details.name, 'Noor');
    },
  );

  for (final invalid in [
    {},
    {...directory(), 'school_id': 20},
    {
      ...directory(),
      'directors': [profile(schoolId: 20)],
    },
    {
      ...directory(),
      'assignments': [assignment(schoolId: 20)],
    },
    {...directory(), 'directors': []},
    {
      ...directory(),
      'assignments': [
        assignment(),
        {...assignment(), 'id': 51},
      ],
    },
    {
      ...directory(),
      'assignments': [
        {...assignment(), 'starts_on': '2026-02-31'},
      ],
    },
    {
      ...directory(),
      'assignments': [assignment(endedOn: '2026-09-01')],
    },
  ]) {
    test('invalid scoped directory is rejected: $invalid', () async {
      final repository = SchoolDirectorRepository(
        client: DirectorApiClient(get: (_) async => json(invalid)),
      );
      await expectLater(
        repository.directory(school),
        failure(DirectorFailure.invalidResponse),
      );
    });
  }

  test(
    'profile create and update use exact scoped verbs and trimmed values',
    () async {
      final calls = <String>[];
      final repository = SchoolDirectorRepository(
        client: DirectorApiClient(
          post: (path, body) async {
            calls.add('POST $path');
            expect(body['name'], 'Noor');
            expect(body.containsKey('organization_id'), isFalse);
            return json({'director': profile()}, 201);
          },
          patch: (path, body) async {
            calls.add('PATCH $path');
            expect(body['experience_years'], 5);
            return json({'director': profile()});
          },
        ),
      );
      await repository.save(school, draft);
      await repository.save(school, draft, directorId: 30);
      expect(calls, [
        'POST ${school.path}/directors',
        'PATCH ${school.path}/directors/30',
      ]);
    },
  );

  test('stale profile response is not successful save', () async {
    final repository = SchoolDirectorRepository(
      client: DirectorApiClient(
        post: (path, body) async => json({
          'director': {...profile(), 'experience_years': 2},
        }, 201),
      ),
    );
    await expectLater(
      repository.save(school, draft),
      failure(DirectorFailure.invalidResponse),
    );
  });

  test(
    'assignment carries reviewed previous assignment ID and dates',
    () async {
      final repository = SchoolDirectorRepository(
        client: DirectorApiClient(
          post: (path, body) async {
            expect(path, '${school.path}/director-assignments');
            expect(body, {
              'director_id': 30,
              'starts_on': '2026-10-01',
              'replace_assignment_id': 49,
            });
            return json({'assignment': assignment()}, 201);
          },
        ),
      );
      await repository.assign(
        school,
        30,
        DateTime(2026, 10, 1),
        replacesAssignmentId: 49,
      );
    },
  );

  test(
    'end request carries identity assertion and preserves historical start',
    () async {
      final repository = SchoolDirectorRepository(
        client: DirectorApiClient(
          patch: (path, body) async {
            expect(path, '${school.path}/director-assignments/50/end');
            expect(body, {
              'ended_on': '2026-10-20',
              'expected_director_id': 30,
            });
            return json({'assignment': assignment(endedOn: '2026-10-20')});
          },
        ),
      );
      await repository.end(
        school,
        DirectorAssignment.fromJson(assignment()),
        DateTime(2026, 10, 20),
      );
    },
  );

  test('wrong-school mutation response is rejected', () async {
    final repository = SchoolDirectorRepository(
      client: DirectorApiClient(
        post: (path, body) async =>
            json({'assignment': assignment(schoolId: 20)}, 201),
      ),
    );
    await expectLater(
      repository.assign(school, 30, DateTime(2026, 10, 1)),
      failure(DirectorFailure.invalidResponse),
    );
  });

  for (final entry in {
    401: DirectorFailure.session,
    403: DirectorFailure.forbidden,
    404: DirectorFailure.unavailable,
    405: DirectorFailure.unavailable,
    501: DirectorFailure.unavailable,
    409: DirectorFailure.conflict,
    422: DirectorFailure.validation,
    429: DirectorFailure.rateLimited,
    500: DirectorFailure.server,
    200: DirectorFailure.invalidResponse,
  }.entries) {
    test(
      'write HTTP ${entry.key} has typed failure and never retries',
      () async {
        var calls = 0;
        final repository = SchoolDirectorRepository(
          client: DirectorApiClient(
            post: (path, body) async {
              calls++;
              return http.Response('<html>error</html>', entry.key);
            },
          ),
        );
        await expectLater(repository.save(school, draft), failure(entry.value));
        expect(calls, 1);
      },
    );
  }

  test('disconnected write is ambiguous and not retried', () async {
    var calls = 0;
    final repository = SchoolDirectorRepository(
      client: DirectorApiClient(
        post: (path, body) async {
          calls++;
          throw http.ClientException('Disconnected');
        },
      ),
    );
    await expectLater(
      repository.save(school, draft),
      failure(DirectorFailure.uncertain),
    );
    expect(calls, 1);
  });
  test('overlapping historical appointments are rejected', () async {
    final repository = SchoolDirectorRepository(
      client: DirectorApiClient(
        get: (_) async => json({
          ...directory(),
          'assignments': [
            {...assignment(endedOn: '2026-10-25'), 'id': 51,
              'starts_on': '2026-10-15'},
            {...assignment(endedOn: '2026-10-20'), 'id': 50},
          ],
        }),
      ),
    );
    await expectLater(repository.directory(school),
        failure(DirectorFailure.invalidResponse));
  });

  test('non-overlapping historical appointments remain readable', () async {
    final repository = SchoolDirectorRepository(
      client: DirectorApiClient(
        get: (_) async => json({
          ...directory(),
          'assignments': [
            {...assignment(endedOn: '2026-10-25'), 'id': 51,
              'starts_on': '2026-10-20'},
            {...assignment(endedOn: '2026-10-20'), 'id': 50},
          ],
        }),
      ),
    );
    final result = await repository.directory(school);
    expect(result.assignments.map((item) => item.id), [51, 50]);
  });

}
