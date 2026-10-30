import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/enrollment/enrollment_models.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/enrollment/enrollment_repository.dart';

import 'enrollment_fakes.dart';

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);
Matcher fails(EnrollmentFailure failure) => throwsA(
  isA<EnrollmentApiException>().having((e) => e.failure, 'failure', failure),
);
Map<String, dynamic> schoolContext() => {
  'school': {'id': 10, 'name': 'School A', 'organization_id': null},
};
Map<String, dynamic> sectionJson() => {
  'id': 20,
  'name': 'A',
  'grade_name': 'Grade 2',
  'academic_year_id': 3,
  'academic_year_name': '2026/2027',
};
void main() {
  test('school scope comes from authenticated context and supports independent schools', () async {
    final calls = <String>[];
    final repo = SchoolEnrollmentRepository(
      client: EnrollmentApiClient(
        get: (path) async {
          calls.add(path);
          if (path.endsWith('context')) return json(schoolContext());
          if (path.endsWith('options')) {
            return json({
              'school_id': 10,
              'sections': [sectionJson()],
            });
          }
          return json({
            'school_id': 10,
            'requests': [enrollmentRequestJson()],
          });
        },
      ),
    );
    final data = await repo.load();
    expect(data.identity.organizationId, isNull);
    expect(data.sections.single.id, 20);
    expect(calls.toSet(), {
      '/school/context',
      '/school/enrollment-requests',
      '/school/enrollment-options',
    });
  });
  for (final foreign in [true, false]) {
    test(
      'foreign ${foreign ? 'inbox' : 'options'} scope is rejected',
      () async {
        final repo = SchoolEnrollmentRepository(
          client: EnrollmentApiClient(
            get: (path) async {
              if (path.endsWith('context')) return json(schoolContext());
              if (path.endsWith('options')) {
                return json({'school_id': foreign ? 10 : 99, 'sections': []});
              }
              return json({'school_id': foreign ? 99 : 10, 'requests': []});
            },
          ),
        );
        await expectLater(
          repo.load(),
          fails(EnrollmentFailure.invalidResponse),
        );
      },
    );
  }
  test('school approval asserts version and confirms original child plus selected section', () async {
    final repo = SchoolEnrollmentRepository(
      client: EnrollmentApiClient(
        post: (path, body) async {
          expect(path, '/school/enrollment-requests/50/decision');
          expect(body, {
            'expected_version': 1,
            'decision': 'approved',
            'section_id': 20,
            'reason': '',
          });
          return json({
            'request': enrollmentRequestJson(status: 'approved', version: 2),
            'enrollment': activeEnrollmentJson(),
          });
        },
      ),
    );
    await repo.decide(
      enrollmentRequest(),
      const EnrollmentDecision(approve: true, sectionId: 20),
    );
  });
  for (final receipt in [
    {'request': enrollmentRequestJson(status: 'approved', version: 2)},
    {
      'request': enrollmentRequestJson(status: 'approved', version: 1),
      'enrollment': activeEnrollmentJson(),
    },
    {
      'request': enrollmentRequestJson(status: 'approved', version: 2),
      'enrollment': {...activeEnrollmentJson(), 'child_id': 7},
    },
    {
      'request': enrollmentRequestJson(status: 'approved', version: 2),
      'enrollment': {...activeEnrollmentJson(), 'school_id': 99},
    },
    {
      'request': enrollmentRequestJson(status: 'approved', version: 2),
      'enrollment': {...activeEnrollmentJson(), 'section_id': 99},
    },
  ]) {
    test(
      'incomplete or mismatched approval cannot claim enrollment: $receipt',
      () async {
        final repo = SchoolEnrollmentRepository(
          client: EnrollmentApiClient(
            post: (path, body) async => json(receipt),
          ),
        );
        await expectLater(
          repo.decide(
            enrollmentRequest(),
            const EnrollmentDecision(approve: true, sectionId: 20),
          ),
          fails(EnrollmentFailure.invalidResponse),
        );
      },
    );
  }
  test('rejection requires reason and does not create enrollment', () async {
    var sends = 0;
    final repo = SchoolEnrollmentRepository(
      client: EnrollmentApiClient(
        post: (path, body) async {
          sends++;
          return json({
            'request': enrollmentRequestJson(status: 'rejected', version: 2),
            'enrollment': null,
          });
        },
      ),
    );
    await expectLater(
      repo.decide(
        enrollmentRequest(),
        const EnrollmentDecision(approve: false),
      ),
      fails(EnrollmentFailure.validation),
    );
    expect(sends, 0);
    await repo.decide(
      enrollmentRequest(),
      const EnrollmentDecision(approve: false, reason: 'Full capacity'),
    );
    expect(sends, 1);
  });
  test('parent history is child-scoped and distinguishes an absent active enrollment', () async {
    final repo = ParentEnrollmentRepository(
      childId: 6,
      client: EnrollmentApiClient(
        get: (path) async {
          expect(path, '/parent/children/6/enrollment-requests');
          return json({
            'child_id': 6,
            'requests': [enrollmentRequestJson()],
            'active_enrollment': null,
          });
        },
      ),
    );
    expect((await repo.load()).canRequest, isFalse);
  });
  for (final data in [
    {'child_id': 7, 'requests': [], 'active_enrollment': null},
    {'child_id': 6, 'requests': []},
    {
      'child_id': 6,
      'requests': [
        {...enrollmentRequestJson(), 'child_id': 7},
      ],
      'active_enrollment': null,
    },
    {
      'child_id': 6,
      'requests': [enrollmentRequestJson(), enrollmentRequestJson()],
      'active_enrollment': null,
    },
    {
      'child_id': 6,
      'requests': [],
      'active_enrollment': {...activeEnrollmentJson(), 'child_id': 7},
    },
  ]) {
    test('foreign or incomplete child history is rejected: $data', () async {
      final repo = ParentEnrollmentRepository(
        childId: 6,
        client: EnrollmentApiClient(get: (path) async => json(data)),
      );
      await expectLater(repo.load(), fails(EnrollmentFailure.invalidResponse));
    });
  }
  test(
    'school search encodes user text and only returns minimal school models',
    () async {
      final repo = ParentEnrollmentRepository(
        childId: 6,
        client: EnrollmentApiClient(
          get: (path) async {
            expect(path, '/parent/enrollment-schools?q=A%26B');
            return json({
              'schools': [
                {'id': 10, 'name': 'School A', 'address': 'Gaza'},
              ],
            });
          },
        ),
      );
      expect((await repo.search(' A&B ')).single.id, 10);
    },
  );
  test('parent submission sends only selected school, never a child copy or parent ID', () async {
    final repo = ParentEnrollmentRepository(
      childId: 6,
      client: EnrollmentApiClient(
        post: (path, body) async {
          expect(path, '/parent/children/6/enrollment-requests');
          expect(body, {'school_id': 10});
          return json({'request': enrollmentRequestJson()}, 201);
        },
      ),
    );
    await repo.submit(enrollmentSchool);
  });
  test(
    'parent submission cannot report approval or a different child',
    () async {
      final repo = ParentEnrollmentRepository(
        childId: 6,
        client: EnrollmentApiClient(
          post: (path, body) async =>
              json({'request': enrollmentRequestJson(status: 'approved')}, 201),
        ),
      );
      await expectLater(
        repo.submit(enrollmentSchool),
        fails(EnrollmentFailure.invalidResponse),
      );
    },
  );
  test(
    'cancel carries expected version and cannot cancel an accepted request',
    () async {
      var sends = 0;
      final repo = ParentEnrollmentRepository(
        childId: 6,
        client: EnrollmentApiClient(
          post: (path, body) async {
            sends++;
            expect(path, '/parent/children/6/enrollment-requests/50/cancel');
            expect(body, {'expected_version': 1});
            return json({
              'request': enrollmentRequestJson(status: 'cancelled', version: 2),
            });
          },
        ),
      );
      await repo.cancel(enrollmentRequest());
      expect(sends, 1);
      await expectLater(
        repo.cancel(enrollmentRequest(status: EnrollmentStatus.approved)),
        fails(EnrollmentFailure.forbidden),
      );
      expect(sends, 1);
    },
  );
  for (final entry in {
    401: EnrollmentFailure.session,
    403: EnrollmentFailure.forbidden,
    404: EnrollmentFailure.unavailable,
    405: EnrollmentFailure.unavailable,
    501: EnrollmentFailure.unavailable,
    409: EnrollmentFailure.conflict,
    422: EnrollmentFailure.validation,
    429: EnrollmentFailure.rateLimited,
    500: EnrollmentFailure.server,
    200: EnrollmentFailure.invalidResponse,
  }.entries) {
    test('HTTP ${entry.key} never silently succeeds or retries', () async {
      var calls = 0;
      final repo = ParentEnrollmentRepository(
        childId: 6,
        client: EnrollmentApiClient(
          post: (path, body) async {
            calls++;
            return http.Response('<html>error</html>', entry.key);
          },
        ),
      );
      await expectLater(repo.submit(enrollmentSchool), fails(entry.value));
      expect(calls, 1);
    });
  }
  test('lost write response is ambiguous and not retried', () async {
    var calls = 0;
    final repo = ParentEnrollmentRepository(
      childId: 6,
      client: EnrollmentApiClient(
        post: (path, body) async {
          calls++;
          throw http.ClientException('Disconnected');
        },
      ),
    );
    await expectLater(
      repo.submit(enrollmentSchool),
      fails(EnrollmentFailure.uncertain),
    );
    expect(calls, 1);
  });
  for (final receipt in [
    {...enrollmentRequestJson(status: 'approved', version: 2),
      'school_name': 'Other school'},
    {...enrollmentRequestJson(status: 'approved', version: 2),
      'child_name': 'Other child'},
  ]) {
    test('approval cannot silently replace child or school identity',
        () async {
      final repo = SchoolEnrollmentRepository(
        client: EnrollmentApiClient(
          post: (_, __) async => json({
            'request': receipt,
            'enrollment': activeEnrollmentJson(),
          }),
        ),
      );
      await expectLater(
        repo.decide(enrollmentRequest(),
            const EnrollmentDecision(approve: true, sectionId: 20)),
        fails(EnrollmentFailure.invalidResponse),
      );
    });
  }

}
