import 'dart:convert';

import 'package:edubridge_app/services/institution_school_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response response(Object data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'resolves account institution before scoped school operations',
    () async {
      final calls = <String>[];
      await http.runWithClient(
        () async {
          final repository = InstitutionSchoolRepository();
          final slug = await repository.resolveOrganization(
            failureMessage: 'Missing institution',
          );
          expect(slug, 'demo-school');
          expect((await repository.loadSchools(slug)).single['id'], 3);
          expect((await repository.loadReport(slug))['summary'], {
            'schools': 1,
          });
          expect(
            (await repository.loadSchool(slug, 3))['school']['name'],
            'مدرسة',
          );
          await repository.createSchool(slug, {
            'name': 'New',
            'slug': 'new-school',
          });
          await repository.updateSchool(slug, 3, {
            'name': 'Updated',
            'address': 'Gaza',
            'phone': '123',
          });
          expect(calls, [
            'GET /api/institutions/my-organization',
            'GET /api/institutions/demo-school/schools',
            'GET /api/institutions/demo-school/management-report',
            'GET /api/institutions/demo-school/schools/3',
            'POST /api/institutions/demo-school/schools',
            'PATCH /api/institutions/demo-school/schools/3',
          ]);
        },
        () => MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.method != 'GET') {
            final fields = jsonDecode(request.body) as Map;
            expect(fields.containsKey('organization_id'), isFalse);
            expect(
              fields['name'],
              request.method == 'POST' ? 'New' : 'Updated',
            );
            return response({}, request.method == 'POST' ? 201 : 200);
          }
          if (request.url.path.endsWith('/my-organization')) {
            return response({
              'organization': {'id': 1, 'slug': 'demo-school'},
            });
          }
          if (request.url.path.endsWith('/management-report')) {
            return response({
              'summary': {'schools': 1},
              'schools': [
                {'school_id': 3}
              ],
            });
          }
          if (request.url.path.endsWith('/schools/3')) {
            return response({
              'school': {'id': 3, 'name': 'مدرسة'},
            });
          }
          return response({
            'schools': [
              {'id': 3, 'name': 'مدرسة'},
            ],
          });
        }),
      );
    },
  );

  for (final organization in [
    {'id': 0, 'slug': 'valid-slug'},
    {'id': 1, 'slug': '../other'},
    {'id': '1', 'slug': 'valid-slug'},
  ]) {
    test('rejects invalid institution context $organization', () async {
      await http.runWithClient(
        () async {
          await expectLater(
            InstitutionSchoolRepository().resolveOrganization(
              failureMessage: 'missing',
            ),
            throwsA(isA<FormatException>()),
          );
        },
        () => MockClient((_) async => response({'organization': organization})),
      );
    });
  }

  test(
    'preserves server rejection and absent account institution failures',
    () async {
      await http.runWithClient(() async {
        final repository = InstitutionSchoolRepository();
        await expectLater(
          repository.loadSchools('demo-school'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'server error',
              contains('Denied'),
            ),
          ),
        );
        await expectLater(
          repository.resolveOrganization(failureMessage: 'No institution'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'context error',
              contains('No institution'),
            ),
          ),
        );
      }, () => MockClient((_) async => response({'error': 'Denied'}, 403)));
    },
  );
}
