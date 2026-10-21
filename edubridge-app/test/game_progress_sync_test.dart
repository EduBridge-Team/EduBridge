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
}
