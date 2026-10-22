import 'dart:convert';

import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('offline attempts survive and retry with the same event ID', () async {
    final attempts = <Map<String, dynamic>>[];
    var online = false;
    final service = GameProgressService(
      post: (_, body) async {
        attempts.add(Map<String, dynamic>.from(body));
        return http.Response('{}', online ? 201 : 503);
      },
    );

    service.begin(childId: 10, gameKey: 'matching');
    await service.record(85);

    final prefs = await SharedPreferences.getInstance();
    final key = 'pending_game_attempts_v2_0';
    final pending = jsonDecode(prefs.getString(key)!) as List;
    expect(pending, hasLength(1));
    expect(pending.single['child_id'], 10);
    expect(pending.single['score'], 85);
    expect(attempts, hasLength(1));
    expect(attempts.single['event_id'], pending.single['event_id']);

    online = true;
    final restarted = GameProgressService(
      post: (_, body) async {
        attempts.add(Map<String, dynamic>.from(body));
        return http.Response('{}', 201);
      },
    );
    await restarted.flushPending();

    expect(attempts, hasLength(2));
    expect(attempts[1]['event_id'], attempts[0]['event_id']);
    expect(attempts[1].containsKey('child_id'), isFalse);
    expect(prefs.containsKey(key), isFalse);
  });

  test('scores are bounded and a stopped game does not record', () async {
    final sent = <Map<String, dynamic>>[];
    final service = GameProgressService(
      post: (_, body) async {
        sent.add(Map<String, dynamic>.from(body));
        return http.Response('{}', 200);
      },
    );

    service.begin(childId: 7, gameKey: 'numbers');
    await service.record(125);
    await service.record(-12);
    service.end();
    await service.record(50);

    expect(sent.map((attempt) => attempt['score']).toList(), [100, 0]);
    expect(sent.every((attempt) => attempt['game_key'] == 'numbers'), isTrue);
  });

  test('permanent rejection is removed while later queued attempts sync', () async {
    var calls = 0;
    final service = GameProgressService(
      post: (_, body) async {
        calls++;
        return http.Response('{}', calls == 1 ? 403 : 200);
      },
    );

    service.begin(childId: 7, gameKey: 'numbers');
    await service.record(80);
    await service.record(90);

    final prefs = await SharedPreferences.getInstance();
    expect(calls, 2);
    expect(prefs.containsKey('pending_game_attempts_v2_0'), isFalse);
  });

  test('rate limiting preserves event ID for a subsequent retry', () async {
    final ids = <String>[];
    var online = false;
    final service = GameProgressService(
      post: (_, body) async {
        ids.add(body['event_id'] as String);
        return http.Response('{}', online ? 200 : 429);
      },
    );

    service.begin(childId: 8, gameKey: 'memory');
    await service.record(70);
    online = true;
    await service.flushPending();

    expect(ids, hasLength(2));
    expect(ids.first, ids.last);
    expect((await SharedPreferences.getInstance())
        .containsKey('pending_game_attempts_v2_0'), isFalse);
  });

  test('reading an unchanged offline queue keeps its persisted payload', () async {
    final raw = jsonEncode([
      {
        'child_id': 10,
        'game_key': 'matching',
        'score': 50,
        'event_id': 'saved-attempt',
      },
    ]);
    SharedPreferences.setMockInitialValues({
      'pending_game_attempts_v2_0': raw,
    });
    final service = GameProgressService(
      post: (_, __) async => http.Response('{}', 503),
    );

    await service.flushPending();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pending_game_attempts_v2_0'), raw);
  });

  test('legacy attempts receive stable IDs and migrate to scoped storage', () async {
    SharedPreferences.setMockInitialValues({
      'pending_game_attempts_v1': jsonEncode([
        {'child_id': 10, 'game_key': 'memory', 'score': 25},
      ]),
    });
    final ids = <String>[];
    final service = GameProgressService(
      post: (_, body) async {
        ids.add(body['event_id'] as String);
        return http.Response('{}', 503);
      },
    );

    await service.flushPending();
    await service.flushPending();

    final prefs = await SharedPreferences.getInstance();
    final pending = jsonDecode(
      prefs.getString('pending_game_attempts_v2_0')!,
    ) as List;
    expect(ids, hasLength(2));
    expect(ids.first, ids.last);
    expect(pending.single['event_id'], ids.first);
    expect(prefs.containsKey('pending_game_attempts_v1'), isFalse);
  });
}
