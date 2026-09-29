// lib/services/reward_service.dart
// نظام المكافآت — نجوم متزامنة مع السيرفر مع fallback محلي للعمل دون اتصال.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class RewardService {
  RewardService._();
  static final RewardService instance = RewardService._();

  String _cacheKey(int childId) => 'child_stars_$childId';
  String _pendingKey(int childId) => 'child_stars_pending_$childId';

  Future<int> getStars(int childId) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final pending = prefs.getInt(_pendingKey(childId)) ?? 0;
      if (pending > 0) {
        final flush = await ApiService.authPost(
          '/children/$childId/rewards/stars',
          {'count': pending},
        );
        if (flush.statusCode >= 200 && flush.statusCode < 300) {
          final body = jsonDecode(flush.body) as Map<String, dynamic>;
          final synced = (body['stars'] as num?)?.toInt() ?? 0;
          await prefs.setInt(_cacheKey(childId), synced);
          await prefs.remove(_pendingKey(childId));
        }
      }

      final res = await ApiService.authGet('/children/$childId/engagement');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final synced = (body['stars'] as num?)?.toInt() ?? 0;
        await prefs.setInt(_cacheKey(childId), synced);
        return synced;
      }
    } catch (_) {
      // Offline fallback أدناه.
    }

    return prefs.getInt(_cacheKey(childId)) ?? 0;
  }

  Future<void> addStar(int childId, {int count = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getInt(_pendingKey(childId)) ?? 0;
    final toSync = pending + count;

    try {
      final res = await ApiService.authPost(
        '/children/$childId/rewards/stars',
        {'count': toSync},
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final synced = (body['stars'] as num?)?.toInt() ??
            (prefs.getInt(_cacheKey(childId)) ?? 0) + toSync;
        await prefs.setInt(_cacheKey(childId), synced);
        await prefs.remove(_pendingKey(childId));
        return;
      }
    } catch (_) {
      // نحفظ الزيادة محلياً كي لا تضيع مكافأة الطفل.
    }

    final current = prefs.getInt(_cacheKey(childId)) ?? 0;
    await prefs.setInt(_cacheKey(childId), current + count);
    await prefs.setInt(_pendingKey(childId), toSync);
  }

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
