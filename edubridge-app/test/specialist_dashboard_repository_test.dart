import 'dart:convert';

import 'package:edubridge_app/services/specialist_dashboard_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  for (final fallback in [false, true]) {
    test('assembles dashboard with ${fallback ? 'directory' : 'profile'} specialty', () async {
      final paths = <String>[];
      await http.runWithClient(() async {
        final data = await SpecialistDashboardRepository().load(currentUserId: 7);
        expect(data.rows.single['child']['id'], 10);
        expect(data.rows.single['stats']['done'], 1);
        expect(data.rows.single['stats']['pct'], 50);
        expect(data.rows.single['stats']['current']['lesson_id'], 22);
        expect(data.lessons.single['id'], 22);
        expect(data.types.single['id'], 3);
        expect(data.teachers.single['id'], 6);
        expect(data.specialists.single['id'], 7);
        expect(data.specialty, fallback ? 'learning_support' : 'educational');
        expect(paths, containsAll([
          '/children', '/lessons', '/disability-types',
          '/users?role=teacher', '/users?role=specialist',
          '/progress/child/10', '/me',
        ]));
      }, () => MockClient((request) async {
        final path = request.url.path.replaceFirst('/api', '');
        final key = request.url.hasQuery ? '$path?${request.url.query}' : path;
        paths.add(key);
        return switch (key) {
          '/children' => response({'children': [{'id': 10}]}),
          '/lessons' => response({'lessons': [{'id': 22}]}),
          '/disability-types' => response({'disability_types': [{'id': 3}]}),
          '/users?role=teacher' => response({'users': [{'id': 6}]}),
          '/users?role=specialist' => response({'users': [{'id': 7, 'specialty': 'نفسي'}]}),
          '/progress/child/10' => response({'progress': [
            {'status': 'done'}, {'status': 'in_progress', 'lesson_id': 22},
          ]}),
          '/me' => fallback ? response({}, 503)
              : response({'user': {'specialty': ' تعليمي '}}),
          _ => throw StateError('Unexpected request: $key'),
        };
      }));
    });
  }

  test('preserves server rejection for the screen localized error policy', () async {
    await http.runWithClient(() async {
      await expectLater(
        SpecialistDashboardRepository().load(currentUserId: null),
        throwsA(isA<SpecialistDashboardLoadException>().having(
          (error) => error.message, 'message', 'Access denied')),
      );
    }, () => MockClient((request) async => request.url.path.endsWith('/children')
        ? response({'error': 'Access denied'}, 403) : response({})));
  });

  test('unavailable child progress stays empty and unknown specialty stays null', () async {
    await http.runWithClient(() async {
      final data = await SpecialistDashboardRepository().load(currentUserId: 7);
      expect(data.rows.single['progress'], isEmpty);
      expect(data.rows.single['stats']['total'], 0);
      expect(data.specialty, isNull);
    }, () => MockClient((request) async {
      if (request.url.path.endsWith('/children')) {
        return response({'children': [{'id': 10}]});
      }
      if (request.url.path.contains('/progress/child/')) {
        return response({'error': 'Unavailable'}, 503);
      }
      return response({});
    }));
  });

  test('transport failures propagate to the screen connection error policy', () async {
    await http.runWithClient(() async {
      await expectLater(SpecialistDashboardRepository().load(currentUserId: 7),
          throwsA(isA<http.ClientException>()));
    }, () => MockClient((request) async => throw http.ClientException('offline')));
  });
}
