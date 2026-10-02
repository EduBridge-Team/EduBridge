import 'dart:convert';
import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userId': 1}));

  test('game events survive restart and retry a lost response with the same ID', () async {
    final accepted = <String>{};
    final ids = <String>[];
    Future<http.Response> post(String path, Map<String, dynamic> body) async {
      final id = body['event_id'] as String;
      ids.add(id);
      accepted.add(id);
      if (ids.length == 1) throw Exception('response lost');
      return http.Response('{}', 201);
    }
    final service = GameProgressService(post: post)..begin(childId: 10, gameKey: 'colors');
    await service.record(95);
    await GameProgressService(post: post).flushPending();
    expect(ids.length, 2);
    expect(ids.first, ids.last);
    expect(accepted.length, 1);
    expect((await SharedPreferences.getInstance()).containsKey('pending_game_attempts_v2_1'), isFalse);
  });

  test('concurrent records retain all offline events and another account cannot flush them', () async {
    var calls = 0;
    var online = false;
    final service = GameProgressService(post: (_, body) async {
      calls++;
      return http.Response('{}', online ? 201 : 503);
    })..begin(childId: 10, gameKey: 'colors');
    await Future.wait(List.generate(5, (_) => service.record(90)));
    final prefs = await SharedPreferences.getInstance();
    final events = jsonDecode(prefs.getString('pending_game_attempts_v2_1')!) as List;
    expect(events.length, 5);
    expect(events.map((event) => event['event_id']).toSet().length, 5);
    final priorCalls = calls;
    online = true;
    await prefs.setInt('userId', 2);
    await service.flushPending();
    expect(calls, priorCalls);
    await prefs.setInt('userId', 1);
    await service.flushPending();
    expect(calls, priorCalls + 5);
    expect(prefs.containsKey('pending_game_attempts_v2_1'), isFalse);
  });
}
