import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/model/schools/school_account.dart';
import 'package:edubridge_app/services/schools/school_account_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const request = SchoolAccountRequest(
  name: ' School ',
  email: ' school@example.org ',
  password: '  pass1234 ',
  passwordConfirmation: '  pass1234 ',
);

Map<String, dynamic> result({int? organizationId}) => {
  'school': {'id': 10, 'name': 'School', 'organization_id': organizationId},
  'director': {'id': 50, 'email': 'school@example.org'},
};

http.Response response(Object body, [int status = 201]) =>
    http.Response(jsonEncode(body), status);

Matcher failsWith(SchoolAccountFailure failure) => throwsA(
  isA<SchoolAccountException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  test(
    'independent creation sends credentials only to provisioning endpoint',
    () async {
      final repository = SchoolAccountRepository(
        post: (path, body) async {
          expect(path, '/admin/school-accounts');
          expect(body, {
            'name': 'School',
            'director_email': 'school@example.org',
          });
          return response(result());
        },
      );
      final account = await repository.createIndependent(request);
      expect(account.schoolId, 10);
      expect(account.accountId, 50);
      expect(account.organizationId, isNull);
    },
  );

  test('optional contact fields are trimmed and included', () {
    const input = SchoolAccountRequest(
      name: 'School',
      email: 's@example.org',
      password: 'password',
      passwordConfirmation: 'password',
      phone: ' 123 ',
      address: ' Gaza ',
    );
    expect(input.toJson()['phone'], '123');
    expect(input.toJson()['address'], 'Gaza');
  });

  test(
    'affiliated creation resolves authenticated context before POST',
    () async {
      final calls = <String>[];
      final repository = SchoolAccountRepository(
        get: (path) async {
          calls.add(path);
          return response({
            'organization': {'id': 4, 'slug': 'demo-institution'},
          }, 200);
        },
        post: (path, body) async {
          calls.add(path);
          expect(body.containsKey('organization_id'), isFalse);
          expect(body.containsKey('role'), isFalse);
          return response(result(organizationId: 4));
        },
      );
      expect((await repository.createAffiliated(request)).organizationId, 4);
      expect(calls, [
        '/institutions/my-organization',
        '/institutions/demo-institution/school-accounts',
      ]);
    },
  );

  for (final context in [
    {'id': 4, 'slug': '../other'},
    {'id': 4},
    {'slug': 'demo-institution'},
    {'id': 0, 'slug': 'demo-institution'},
  ]) {
    test('invalid institution context blocks POST: $context', () async {
      var posts = 0;
      final repository = SchoolAccountRepository(
        get: (_) async => response({'organization': context}, 200),
        post: (path, body) async {
          posts++;
          return response(result());
        },
      );
      await expectLater(
        repository.createAffiliated(request),
        failsWith(SchoolAccountFailure.invalidResponse),
      );
      expect(posts, 0);
    });
  }

  test('unauthorized institution lookup never posts credentials', () async {
    var posts = 0;
    final repository = SchoolAccountRepository(
      get: (_) async => http.Response('', 403),
      post: (path, body) async {
        posts++;
        return response(result());
      },
    );
    await expectLater(
      repository.createAffiliated(request),
      failsWith(SchoolAccountFailure.forbidden),
    );
    expect(posts, 0);
  });

  for (final entry in {
    401: SchoolAccountFailure.unauthorized,
    403: SchoolAccountFailure.forbidden,
    404: SchoolAccountFailure.unavailable,
    405: SchoolAccountFailure.unavailable,
    501: SchoolAccountFailure.unavailable,
    409: SchoolAccountFailure.conflict,
    422: SchoolAccountFailure.validation,
    429: SchoolAccountFailure.rateLimited,
    500: SchoolAccountFailure.server,
    200: SchoolAccountFailure.invalidResponse,
  }.entries) {
    test('HTTP ${entry.key} cannot report success', () async {
      var posts = 0;
      final repository = SchoolAccountRepository(
        post: (path, body) async {
          posts++;
          return http.Response('<html>error</html>', entry.key);
        },
      );
      await expectLater(
        repository.createIndependent(request),
        failsWith(entry.value),
      );
      expect(posts, 1, reason: 'POST must not be retried automatically');
    });
  }

  test('422 preserves field names without raw server messages', () async {
    final repository = SchoolAccountRepository(
      post: (path, body) async => response({
        'errors': {
          'email': ['Already used'],
        },
      }, 422),
    );
    await expectLater(
      repository.createIndependent(request),
      throwsA(
        isA<SchoolAccountException>().having((e) => e.fields, 'fields', {
          'email',
        }),
      ),
    );
  });

  for (final invalid in [
    {},
    {
      'school': {'id': 10},
    },
    [],
    {
      ...result(),
      'director': {'id': 50, 'email': 'other@example.org'},
    },
    {
      ...result(),
      'director': {'id': 0, 'email': 'school@example.org'},
    },
    result(organizationId: 4),
    {
      ...result(),
      'school': {'id': 10, 'name': 'A different school', 'organization_id': null},
    },
    {
      ...result(),
      'school': {'id': 10, 'name': 'School'},
    },
  ]) {
    test(
      'invalid or mismatched successful body is rejected: $invalid',
      () async {
        final repository = SchoolAccountRepository(
          post: (path, body) async => response(invalid),
        );
        await expectLater(
          repository.createIndependent(request),
          failsWith(SchoolAccountFailure.invalidResponse),
        );
      },
    );
  }

  test('affiliated response must belong to resolved institution', () async {
    final repository = SchoolAccountRepository(
      get: (_) async => response({
        'organization': {'id': 4, 'slug': 'demo-institution'},
      }, 200),
      post: (path, body) async => response(result(organizationId: 7)),
    );
    await expectLater(
      repository.createAffiliated(request),
      failsWith(SchoolAccountFailure.invalidResponse),
    );
  });

  test('malformed JSON on 201 is never success', () async {
    final repository = SchoolAccountRepository(
      post: (path, body) async => http.Response('oops', 201),
    );
    await expectLater(
      repository.createIndependent(request),
      failsWith(SchoolAccountFailure.invalidResponse),
    );
  });

  test(
    'connection failure after POST is ambiguous and is not retried',
    () async {
      var posts = 0;
      final repository = SchoolAccountRepository(
        post: (path, body) async {
          posts++;
          throw http.ClientException('disconnected');
        },
      );
      await expectLater(
        repository.createIndependent(request),
        failsWith(SchoolAccountFailure.uncertain),
      );
      expect(posts, 1);
    },
  );

  test('POST timeout is ambiguous', () async {
    final repository = SchoolAccountRepository(
      post: (path, body) async => throw TimeoutException('timeout'),
    );
    await expectLater(
      repository.createIndependent(request),
      failsWith(SchoolAccountFailure.uncertain),
    );
  });
}
