import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class GameProgressService {
  GameProgressService._();
  static final GameProgressService instance = GameProgressService._();

  static const _pendingKey = 'pending_game_attempts_v1';

  int? _childId;
  String? _gameKey;
  DateTime? _startedAt;

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

  Future<void> record(int score) async {
    final childId = _childId;
    final gameKey = _gameKey;
    if (childId == null || gameKey == null) return;

    final normalized = score.clamp(0, 100);
    final stars = normalized >= 90
        ? 3
        : normalized >= 70
            ? 2
            : normalized >= 50
                ? 1
                : 0;
    final startedAt = _startedAt;
    final duration = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inSeconds.clamp(1, 86400);

    final attempt = <String, dynamic>{
      'child_id': childId,
      'game_key': gameKey,
      'score': normalized,
      'stars_earned': stars,
      if (duration != null) 'duration_seconds': duration,
    };

    await _flushPending();

    try {
      final res = await ApiService.authPost(
        '/children/$childId/game-attempts',
        {
          'game_key': gameKey,
          'score': normalized,
          'stars_earned': stars,
          if (duration != null) 'duration_seconds': duration,
        },
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        await _enqueue(attempt);
      }
    } catch (_) {
      await _enqueue(attempt);
    } finally {
      // إذا أعاد الطفل اللعبة من نفس الشاشة نحسب مدة جديدة.
      _startedAt = DateTime.now();
    }
  }

  Future<void> flushPending() => _flushPending();

  Future<void> _flushPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return;

    List<dynamic> items;
    try {
      final decoded = jsonDecode(raw);
      items = decoded is List ? decoded : [];
    } catch (_) {
      items = [];
    }
    if (items.isEmpty) {
      await prefs.remove(_pendingKey);
      return;
    }

    final remaining = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is! Map) continue;
      final attempt = Map<String, dynamic>.from(item);
      final childId = (attempt['child_id'] as num?)?.toInt();
      if (childId == null) continue;

      try {
        final res = await ApiService.authPost(
          '/children/$childId/game-attempts',
          {
            'game_key': attempt['game_key'],
            'score': attempt['score'],
            'stars_earned': attempt['stars_earned'] ?? 0,
            if (attempt['duration_seconds'] != null)
              'duration_seconds': attempt['duration_seconds'],
          },
        );
        if (res.statusCode < 200 || res.statusCode >= 300) {
          remaining.add(attempt);
        }
      } catch (_) {
        remaining.add(attempt);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(remaining));
    }
  }

  Future<void> _enqueue(Map<String, dynamic> attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    List<dynamic> current = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) current = decoded;
      } catch (_) {}
    }

    current.add(attempt);
    // حد أعلى حتى لا تنمو القائمة بلا حدود عند انقطاع طويل.
    final compact = current.length > 100
        ? current.sublist(current.length - 100)
        : current;
    await prefs.setString(_pendingKey, jsonEncode(compact));
  }
}
