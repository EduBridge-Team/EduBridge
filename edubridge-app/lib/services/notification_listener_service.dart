// services/notification_listener_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'websocket_service.dart';

/// يستمع لإشعارات WebSocket ويحدّث الواجهة فورياً
class NotificationListenerService {
  NotificationListenerService._();
  static final NotificationListenerService instance =
      NotificationListenerService._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, dynamic>?> latestNotification =
      ValueNotifier(null);
  final ValueNotifier<List<dynamic>> notifications =
      ValueNotifier<List<dynamic>>([]);

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      unreadCount.value = await ApiService.getUnreadNotificationsCount();
      notifications.value = await ApiService.getNotifications();
    } catch (_) {}

    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _onWebSocketMessage(Map<String, dynamic> data) {
    if (data['type'] != 'notification') return;

    final payload = data['payload'] as Map<String, dynamic>?;
    if (payload == null) return;

    if (payload['is_read'] != true) {
      unreadCount.value = unreadCount.value + 1;
    }

    notifications.value = [payload, ...notifications.value];
    latestNotification.value = payload;
  }

  Future<void> refresh() async {
    try {
      unreadCount.value = await ApiService.getUnreadNotificationsCount();
    } catch (_) {}
  }

  Future<void> reloadAll() async {
    try {
      notifications.value = await ApiService.getNotifications();
      unreadCount.value = await ApiService.getUnreadNotificationsCount();
    } catch (_) {}
  }

  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    _initialized = false;
  }
}