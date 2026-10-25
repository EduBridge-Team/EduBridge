import 'dart:convert';

import 'package:edubridge_app/features/case_discussions/data/case_creation_repository.dart';
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
    SharedPreferences.setMockInitialValues({'role': 'specialist', 'userId': 8});
  });

  test(
    'directory returns only assigned children and eligible professional roles',
    () async {
      final paths = <String>[];
      await http.runWithClient(
        () async {
          final directory = await CaseCreationRepository().loadDirectory();
          expect(directory.currentUserId, 8);
          expect(directory.children.map((child) => child['id']), [1]);
          expect(directory.users.map((user) => user['id']), [8, 7]);
          expect(paths.toSet(), {'/api/children', '/api/users'});
        },
        () => MockClient((request) async {
          paths.add(request.url.path);
          return request.url.path.endsWith('/children')
              ? response({
                  'children': [
                    {
                      'id': 1,
                      'specialist_ids': [8],
                    },
                    {'id': 2, 'specialist_id': 99},
                  ],
                })
              : response({
                  'users': [
                    {'id': 8, 'role': 'specialist'},
                    {'id': 7, 'role': 'teacher'},
                    {'id': 3, 'role': 'parent'},
                  ],
                });
        }),
      );
    },
  );

  test(
    'partial directory rejection fails instead of offering a partial team',
    () async {
      await http.runWithClient(
        () async {
          await expectLater(
            CaseCreationRepository().loadDirectory(),
            throwsStateError,
          );
        },
        () => MockClient(
          (request) async =>
              response({}, request.url.path.endsWith('/users') ? 403 : 200),
        ),
      );
    },
  );

  test('creation preserves the existing request fields and reports missing receipt', () async {
    var receipt = true;
    await http.runWithClient(
      () async {
        final repository = CaseCreationRepository();
        Future<bool> create() => repository.create(
          childId: 1,
          topic: 'موضوع',
          description: null,
          participantIds: [8, 7],
        );
        expect(await create(), isTrue);
        receipt = false;
        expect(await create(), isFalse);
      },
      () => MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/case-discussions');
        expect(jsonDecode(request.body), {
          'child_id': 1,
          'topic': 'موضوع',
          'description': null,
          'participant_ids': [8, 7],
        });
        return response(
          receipt
              ? {
                  'discussion': {'id': 12},
                }
              : {},
          201,
        );
      }),
    );
  });

  test('creation rejection retains server error for the form retry', () async {
    await http.runWithClient(() async {
      await expectLater(
        CaseCreationRepository().create(
          childId: 1,
          topic: 'topic',
          description: '',
          participantIds: [8, 7],
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Denied'),
          ),
        ),
      );
    }, () => MockClient((_) async => response({'error': 'Denied'}, 403)));
  });
}
