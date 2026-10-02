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

  void end() { _childId = null; _gameKey = null; _startedAt = null; }

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
      await prefs.setString(key, jsonEncode(queue));
      await _flush(prefs, key, queue);
    });
  }

  Future<String> _ownerKey() async => 'pending_game_attempts_v2_${await ApiService.getUserId() ?? 0}';

  Future<List<Map<String, dynamic>>> _queue(SharedPreferences prefs, String key) async {
    final raw = prefs.getString(key) ?? prefs.getString('pending_game_attempts_v1');
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    final queue = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    for (final item in queue) { item['event_id'] ??= newSyncEventId(); }
    await prefs.setString(key, jsonEncode(queue));
    await prefs.remove('pending_game_attempts_v1');
    return queue;
  }

  Future<void> flushPending() => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _ownerKey();
    await _flush(prefs, key, await _queue(prefs, key));
  });

  Future<void> _flush(SharedPreferences prefs, String key, List<Map<String, dynamic>> queue) async {
    while (queue.isNotEmpty) {
      final attempt = queue.first;
      final childId = (attempt['child_id'] as num).toInt();
      if (await _ownerKey() != key) return;
      final payload = Map<String, dynamic>.from(attempt)..remove('child_id');
      try {
        final response = await _post('/children/$childId/game-attempts', payload);
        if (response.statusCode < 200 || response.statusCode >= 300) return;
      } catch (_) { return; }
      queue.removeAt(0);
      await prefs.setString(key, jsonEncode(queue));
    }
    await prefs.remove(key);
  }
}
