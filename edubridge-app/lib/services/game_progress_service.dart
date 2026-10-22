import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'sync_event.dart';

class GameProgressService {
  GameProgressService({Future<http.Response> Function(String, Map<String, dynamic>)? post})
      : _post = post ?? ApiService.authPost;
  static final GameProgressService instance = GameProgressService();
  final Future<http.Response> Function(String, Map<String, dynamic>) _post;
  Future<void> _tail = Future<void>.value();
  int? _childId;
  String? _gameKey;
  DateTime? _startedAt;

  Future<void> _serialize(Future<void> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  void begin({required int? childId, required String gameKey}) {
    _childId = childId;
    _gameKey = gameKey;
    _startedAt = DateTime.now();
  }

  void end() {
    _childId = null;
    _gameKey = null;
    _startedAt = null;
  }

  Future<void> record(int score) {
    final childId = _childId;
    final gameKey = _gameKey;
    if (childId == null || gameKey == null) return Future<void>.value();
    final started = _startedAt;
    _startedAt = DateTime.now();
    final attempt = <String, dynamic>{
      'child_id': childId, 'game_key': gameKey, 'score': score.clamp(0, 100),
      'event_id': newSyncEventId(),
      if (started != null) 'duration_seconds': DateTime.now().difference(started).inSeconds.clamp(1, 86400),
    };
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final key = await _ownerKey();
      final queue = await _queue(prefs, key);
      queue.add(attempt);
      // Enqueue before sending: crashes/lost HTTP responses retry the same event ID.
      await _persistQueue(prefs, key, queue);
      await _flush(prefs, key, queue);
    });
  }

  Future<String> _ownerKey() async =>
      'pending_game_attempts_v2_${await ApiService.getUserId() ?? 0}';

  Future<List<Map<String, dynamic>>> _queue(SharedPreferences prefs, String key) async {
    final current = prefs.getString(key);
    final legacy = current == null
        ? prefs.getString('pending_game_attempts_v1')
        : null;
    final raw = current ?? legacy;
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    final queue = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    var addedEventIds = false;
    for (final item in queue) {
      if (item['event_id'] == null) {
        item['event_id'] = newSyncEventId();
        addedEventIds = true;
      }
    }
    // Reads must not rewrite an unchanged queue. Legacy migration and missing
    // event IDs are persisted before removing the old storage key.
    if (legacy != null || addedEventIds) {
      await _persistQueue(prefs, key, queue);
    }
    if (legacy != null) {
      await prefs.remove('pending_game_attempts_v1');
    }
    return queue;
  }

  Future<void> flushPending() => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _ownerKey();
    await _flush(prefs, key, await _queue(prefs, key));
  });

  Future<void> _persistQueue(
    SharedPreferences prefs,
    String key,
    List<Map<String, dynamic>> queue,
  ) async {
    if (!await prefs.setString(key, jsonEncode(queue))) {
      throw StateError('Unable to persist game events');
    }
  }

  Future<void> _flush(SharedPreferences prefs, String key, List<Map<String, dynamic>> queue) async {
    var queueIndex = 0;
    while (queueIndex < queue.length) {
      final attempt = queue[queueIndex];
      final childId = (attempt['child_id'] as num).toInt();
      if (await _ownerKey() != key) return;
      final payload = Map<String, dynamic>.from(attempt)..remove('child_id');
      try {
        final response = await _post('/children/$childId/game-attempts', payload);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          // HTTP 408 is transient like 429 and server errors: keep the event ID.
          if (response.statusCode >= 500 ||
              response.statusCode == 429 ||
              response.statusCode == 408) {
            return;
          }
          // Discard permanently rejected attempts so they cannot block retries.
          queue.removeAt(queueIndex);
          await _persistQueue(prefs, key, queue);
          continue;
        }
      } catch (_) {
        return;
      }
      queue.removeAt(queueIndex);
      await _persistQueue(prefs, key, queue);
    }
    if (queue.isEmpty) await prefs.remove(key);
  }
}
