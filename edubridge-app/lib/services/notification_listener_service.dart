// services/notification_listener_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'websocket_service.dart';

/// يستمع لإشعارات WebSocket ويحدّث الواجهة فورياً
class NotificationListenerService {
  NotificationListenerService({
    Future<List<dynamic>> Function()? fetchNotifications,
    Future<int> Function()? fetchUnreadCount,
  }) : _fetchNotifications = fetchNotifications ?? ApiService.getNotifications,
       _fetchUnreadCount = fetchUnreadCount ?? ApiService.getUnreadNotificationsCount;

  final Future<List<dynamic>> Function() _fetchNotifications;
  final Future<int> Function() _fetchUnreadCount;

  @visibleForTesting
  Future<void> pollNow() => _pollForNotifications();
  static final NotificationListenerService instance = NotificationListenerService();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, dynamic>?> latestNotification =
      ValueNotifier(null);
  final ValueNotifier<List<dynamic>> notifications =
      ValueNotifier<List<dynamic>>([]);

  bool _initialized = false;
  Timer? _pollTimer;
  int? _latestKnownId;
  int _generation = 0;
  bool _pollInFlight = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final generation = ++_generation;

    try {
      final count = await _fetchUnreadCount();
      final items = await _fetchNotifications();
      if (!_initialized || generation != _generation) return;
      unreadCount.value = count;
      notifications.value = items;
      _latestKnownId = _newestNotificationId(notifications.value);
    } catch (_) {}

    if (!_initialized || generation != _generation) return;
    WebSocketService().addListener(_onWebSocketMessage);

    // Production may temporarily run without a WebSocket endpoint.
    // Keep a lightweight foreground fallback so urgent notifications are
    // surfaced within seconds instead of waiting for a manual refresh.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollForNotifications(),
    );
  }

  int? _notificationId(dynamic item) {
    if (item is! Map) return null;
    final value = item['id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int? _newestNotificationId(List<dynamic> items) {
    int? latest;
    for (final item in items) {
      final id = _notificationId(item);
      if (id != null && (latest == null || id > latest)) latest = id;
    }
    return latest;
  }

  Future<void> _pollForNotifications() async {
    if (!_initialized || _pollInFlight) return;
    _pollInFlight = true;
    final generation = _generation;

    try {
      final fetched = await _fetchNotifications();
      final count = await _fetchUnreadCount();
      if (!_initialized || generation != _generation) return;
      final newest = _newestNotificationId(fetched);
      final previous = _latestKnownId;

      notifications.value = fetched;
      unreadCount.value = count;

      if (newest != null && (previous == null || newest > previous)) {
        final fresh = fetched.where((item) {
          final id = _notificationId(item);
          return id != null && (previous == null || id > previous);
        }).toList();

        if (fresh.isNotEmpty && fresh.first is Map) {
          latestNotification.value =
              Map<String, dynamic>.from(fresh.first as Map);
        }
      }

      if (newest != null) _latestKnownId = newest;
    } catch (_) {
      // Offline/background transition: next polling cycle will retry.
    } finally {
      if (generation == _generation) _pollInFlight = false;
    }
  }

  void _onWebSocketMessage(Map<String, dynamic> data) {
    if (data['type'] != 'notification') return;

    final payload = data['payload'] as Map<String, dynamic>?;
    if (payload == null) return;

    if (payload['is_read'] != true) {
      unreadCount.value = unreadCount.value + 1;
    }

    notifications.value = [payload, ...notifications.value];
    final id = _notificationId(payload);
    if (id != null && (_latestKnownId == null || id > _latestKnownId!)) {
      _latestKnownId = id;
    }
    latestNotification.value = payload;
  }

  Future<void> refresh() async {
    final generation = _generation;
    try {
      final count = await _fetchUnreadCount();
      if (_initialized && generation == _generation) unreadCount.value = count;
    } catch (_) {}
  }

  Future<void> reloadAll() async {
    final generation = _generation;
    try {
      final items = await _fetchNotifications();
      final count = await _fetchUnreadCount();
      if (!_initialized || generation != _generation) return;
      notifications.value = items;
      unreadCount.value = count;
    } catch (_) {}
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    WebSocketService().removeListener(_onWebSocketMessage);
    ++_generation;
    _latestKnownId = null;
    _initialized = false;
    _pollInFlight = false;
    unreadCount.value = 0;
    latestNotification.value = null;
    notifications.value = [];
  }
}
