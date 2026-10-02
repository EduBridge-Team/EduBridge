// lib/services/reward_service.dart
// نظام المكافآت — نجوم متزامنة مع السيرفر مع fallback محلي للعمل دون اتصال.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'sync_event.dart';

class RewardService {
  RewardService({
    Future<http.Response> Function(String)? get,
    Future<http.Response> Function(String, Map<String, dynamic>)? post,
  }) : _get = get ?? ApiService.authGet, _post = post ?? ApiService.authPost;

  static final RewardService instance = RewardService();
  final Future<http.Response> Function(String) _get;
  final Future<http.Response> Function(String, Map<String, dynamic>) _post;
  Future<void> _tail = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  String _cacheKey(int childId, int? owner) => 'child_stars_v2_${owner ?? 0}_$childId';
  String _queueKey(int childId, int? owner) => 'child_stars_queue_v2_${owner ?? 0}_$childId';

  Future<Map<String, dynamic>> _queue(int childId, int? owner, SharedPreferences prefs) async {
    final raw = prefs.getString(_queueKey(childId, owner));
    if (raw != null) return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final pending = prefs.getInt('child_stars_pending_$childId') ?? 0;
    final queue = <String, dynamic>{'pending': pending};
    if (pending > 0) {
      // Persist migration before removing the legacy counter.
      if (!await prefs.setString(_queueKey(childId, owner), jsonEncode(queue))) throw StateError('Unable to persist reward events');
      await prefs.setInt(_cacheKey(childId, owner), prefs.getInt('child_stars_$childId') ?? pending);
    }
    await prefs.remove('child_stars_pending_$childId');
    return queue;
  }

  Future<void> _sync(int childId, int? owner, SharedPreferences prefs) async {
    final queue = await _queue(childId, owner, prefs);
    var pending = (queue['pending'] as num).toInt();
    while (pending > 0) {
      final flight = queue['flight'] is Map
          ? Map<String, dynamic>.from(queue['flight'] as Map)
          : <String, dynamic>{'count': pending > 20 ? 20 : pending, 'event_id': newSyncEventId()};
      queue['flight'] = flight;
      if (!await prefs.setString(_queueKey(childId, owner), jsonEncode(queue))) throw StateError('Unable to persist reward events');
      if (await ApiService.getUserId() != owner) return;
      final response = await _post('/children/$childId/rewards/stars', flight);
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      pending -= (flight['count'] as num).toInt();
      queue['pending'] = pending;
      queue.remove('flight');
      // Pending count and the acknowledged event are committed in one preference write.
      if (!await prefs.setString(_queueKey(childId, owner), jsonEncode(queue))) throw StateError('Unable to persist reward events');
      final serverStars = (body['stars'] as num?)?.toInt();
      if (serverStars != null) await prefs.setInt(_cacheKey(childId, owner), serverStars + pending);
    }
    await prefs.remove(_queueKey(childId, owner));
  }

  Future<int> getStars(int childId) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final owner = await ApiService.getUserId();
    try {
      await _sync(childId, owner, prefs);
      final response = await _get('/children/$childId/engagement');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final queue = await _queue(childId, owner, prefs);
        final total = ((body['stars'] as num?)?.toInt() ?? 0) + (queue['pending'] as num).toInt();
        await prefs.setInt(_cacheKey(childId, owner), total);
        return total;
      }
    } catch (_) {}
    return prefs.getInt(_cacheKey(childId, owner)) ?? 0;
  });

  Future<void> addStar(int childId, {int count = 1}) => _serialize(() async {
    if (count <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final owner = await ApiService.getUserId();
    final queue = await _queue(childId, owner, prefs);
    queue['pending'] = (queue['pending'] as num).toInt() + count;
    if (!await prefs.setString(_queueKey(childId, owner), jsonEncode(queue))) throw StateError('Unable to persist reward events');
    await prefs.setInt(_cacheKey(childId, owner), (prefs.getInt(_cacheKey(childId, owner)) ?? 0) + count);
    try { await _sync(childId, owner, prefs); } catch (_) {}
  });

  /// إظهار مكافأة بصرية
  static Future<void> showReward(
    BuildContext context, {
    required String message,
    String emoji = '⭐',
    int stars = 1,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RewardOverlay(
        message: message,
        emoji: emoji,
        stars: stars,
      ),
    );

    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 2200));
    entry.remove();
  }
}

class _RewardOverlay extends StatefulWidget {
  final String message;
  final String emoji;
  final int stars;

  const _RewardOverlay({
    required this.message,
    required this.emoji,
    required this.stars,
  });

  @override
  State<_RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<_RewardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1).animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.stars,
                      (_) => const Text('⭐', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF2842B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
