import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/schools/school_account.dart';
import 'package:edubridge_app/services/schools/school_account_repository.dart';

void main() {
  const request = SchoolAccountRequest(
    name: 'School One',
    email: 'school@example.com',
    password: 'securePassword123',
    passwordConfirmation: 'securePassword123',
  );

  String success({int? organizationId}) => jsonEncode({
    'school': {
      'id': 10,
      'name': 'School One',
      'organization_id': organizationId,
    },
    'account': {
      'id': 20,
      'email': 'school@example.com',
      'role': 'school',
    },
  });

  test('independent provision uses dedicated account API, not school CRUD', () async {
    String? postedPath;
    Map<String, dynamic>? postedBody;
    final repo = SchoolAccountRepository(
      post: (path, body) async {
        postedPath = path;
        postedBody = body;
        return http.Response(success(), 201);
      },
      get: (_) async => throw StateError('independent must not query institution'),
    );
    final account = await repo.createIndependent(request);
    expect(postedPath, '/admin/school-accounts');
    expect(postedBody!['email'], 'school@example.com');
    expect(postedBody!['password_confirmation'], request.passwordConfirmation);
    expect(account.organizationId, isNull);
  });

  test('affiliated provision resolves signed-in institution for each action', () async {
    String? postedPath;
    final repo = SchoolAccountRepository(
      get: (path) async {
        expect(path, '/institutions/my-organization');
        return http.Response(jsonEncode({
          'organization': {'id': 7, 'slug': 'jabalia'}
        }), 200);
      },
      post: (path, body) async {
        postedPath = path;
        return http.Response(success(organizationId: 7), 201);
      },
    );
    expect((await repo.createAffiliated(request)).organizationId, 7);
    expect(postedPath, '/institutions/jabalia/school-accounts');
  });

  test('affiliated account rejects a wrong institution in API response', () async {
    final repo = SchoolAccountRepository(
      get: (_) async => http.Response(jsonEncode({
        'organization': {'id': 7, 'slug': 'jabalia'}
      }), 200),
      post: (_, __) async => http.Response(success(organizationId: 8), 201),
    );
    await expectLater(
      repo.createAffiliated(request),
      throwsA(isA<SchoolAccountException>().having(
        (e) => e.failure, 'failure', SchoolAccountFailure.invalidResponse,
      )),
    );
  });

  test('invalid institution response prevents any write', () async {
    var writes = 0;
    final repo = SchoolAccountRepository(
      get: (_) async => http.Response(jsonEncode({
        'organization': {'id': 7, 'slug': '../another'}
      }), 200),
      post: (_, __) async {
        writes++;
        return http.Response(success(), 201);
      },
    );
    await expectLater(repo.createAffiliated(request), throwsA(
      isA<SchoolAccountException>().having(
        (e) => e.failure, 'failure', SchoolAccountFailure.invalidResponse,
      ),
    ));
    expect(writes, 0);
  });

  test('409 is a conflict and never reports successful provisioning', () async {
    final repo = SchoolAccountRepository(
      post: (_, __) async => http.Response('{}', 409),
    );
    await expectLater(repo.createIndependent(request), throwsA(
      isA<SchoolAccountException>().having(
        (e) => e.failure, 'failure', SchoolAccountFailure.conflict,
      ),
    ));
  });

  test('unexpected successful status is rejected, not treated as created', () async {
    final repo = SchoolAccountRepository(
      post: (_, __) async => http.Response(success(), 200),
    );
    await expectLater(repo.createIndependent(request), throwsA(
      isA<SchoolAccountException>().having(
        (e) => e.failure, 'failure', SchoolAccountFailure.invalidResponse,
      ),
    ));
  });
  test('socket failure while reading institution is a network error and never posts', () async {
    var posts = 0;
    final repo = SchoolAccountRepository(
      get: (_) async => throw const SocketException('offline'),
      post: (_, __) async {
        posts++;
        return http.Response(success(organizationId: 7), 201);
      },
    );
    await expectLater(repo.createAffiliated(request), throwsA(
      isA<SchoolAccountException>().having(
        (e) => e.failure, 'failure', SchoolAccountFailure.network,
      ),
    ));
    expect(posts, 0);
  });

  test('socket failure after POST stays uncertain and never retries', () async {
    var posts = 0;
    final repo = SchoolAccountRepository(
      post: (_, __) async {
        posts++;
        throw const SocketException('connection dropped');
      },
    );
    await expectLater(repo.createIndependent(request), throwsA(
      isA<SchoolAccountException>().having(
        (e) => e.failure, 'failure', SchoolAccountFailure.uncertain,
      ),
    ));
    expect(posts, 1);
  });

  for (final entry in {
    401: SchoolAccountFailure.unauthorized,
    403: SchoolAccountFailure.forbidden,
  }.entries) {
    test('role/identity denial ${entry.key} is not mistaken for success', () async {
      final repo = SchoolAccountRepository(
        post: (_, __) async => http.Response('{}', entry.key),
      );
      await expectLater(repo.createIndependent(request), throwsA(
        isA<SchoolAccountException>().having(
          (e) => e.failure, 'failure', entry.value,
        ),
      ));
    });
  }

  test('affiliated institution access denial sends no credentials', () async {
    var writes = 0;
    final repo = SchoolAccountRepository(
      get: (_) async => http.Response('{}', 403),
      post: (_, __) async {
        writes++;
        return http.Response(success(organizationId: 7), 201);
      },
    );
    await expectLater(repo.createAffiliated(request), throwsA(
      isA<SchoolAccountException>().having(
        (e) => e.failure, 'failure', SchoolAccountFailure.forbidden,
      ),
    ));
    expect(writes, 0);
  });

}
