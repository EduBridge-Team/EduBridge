import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_page.dart';
import 'websocket_service.dart';

typedef FetchNotificationPage = Future<NotificationPage> Function({int? beforeId, int? afterId});

class NotificationListenerService {
  NotificationListenerService({
    FetchNotificationPage? fetchPage,
    Future<int> Function()? fetchUnreadCount,
  }) : _fetchPage = fetchPage ?? ApiService.getNotificationPage,
       _fetchUnreadCount = fetchUnreadCount ?? ApiService.getUnreadNotificationsCount;

  final FetchNotificationPage _fetchPage;
  final Future<int> Function() _fetchUnreadCount;
  static final NotificationListenerService instance = NotificationListenerService();
  final ValueNotifier<int> unreadCount = ValueNotifier(0);
  final ValueNotifier<Map<String, dynamic>?> latestNotification = ValueNotifier(null);
  final ValueNotifier<List<dynamic>> notifications = ValueNotifier([]);
  final ValueNotifier<bool> hasMore = ValueNotifier(false);

  bool _initialized = false;
  bool _hasBaseline = false;
  bool _pollInFlight = false;
  Timer? _pollTimer;
  int _generation = 0;
  int _afterId = 0;
  int? _beforeId;
  Future<void> _tail = Future.value();

  bool _active(int generation) => _initialized && generation == _generation;

  // History, refresh and polling share a queue so their cursors cannot race.
  Future<void> _serial(Future<void> Function(int) action) {
    final generation = _generation;
    final result = _tail.then((_) async {
      if (_active(generation)) await action(generation);
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final generation = ++_generation;
    try { await reloadAll(); } catch (_) {}
    if (!_active(generation)) return;
    WebSocketService().addListener(_onWebSocketMessage);
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollForNotifications());
  }

  List<dynamic> _merge(List<dynamic> incoming) {
    final byId = <int, Map<String, dynamic>>{};
    for (final row in notifications.value) {
      byId[row['id'] as int] = Map<String, dynamic>.from(row as Map);
    }
    for (final row in incoming) {
      final id = row['id'] as int;
      byId[id] = {...Map<String, dynamic>.from(row as Map),
        // Read status is monotonic; delayed responses must not undo a local read.
        if (byId[id]?['is_read'] == true) 'is_read': true,
      };
    }
    return byId.values.toList()..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
  }

  Future<void> reloadAll() => _serial((generation) async {
    final page = await _fetchPage();
    if (!_active(generation)) return;
    // Preserve WebSocket arrivals received while the history request was running.
    final arrivals = notifications.value.where((row) => (row['id'] as int) > page.afterId).toList();
    final merged = _merge(page.items);
    final ids = {...page.items.map((row) => row['id']), ...arrivals.map((row) => row['id'])};
    notifications.value = merged.where((row) => ids.contains(row['id'])).toList();
    unreadCount.value = page.unreadCount;
    hasMore.value = page.hasMore;
    _beforeId = page.beforeId;
    _afterId = page.afterId;
    _hasBaseline = true;
  });

  Future<void> loadMore() => _serial((generation) async {
    if (!hasMore.value || _beforeId == null) return;
    final page = await _fetchPage(beforeId: _beforeId);
    if (!_active(generation)) return;
    notifications.value = _merge(page.items);
    unreadCount.value = page.unreadCount;
    _beforeId = page.beforeId;
    hasMore.value = page.hasMore;
  });

  @visibleForTesting
  Future<void> pollNow() => _pollForNotifications();

  Future<void> _pollForNotifications() async {
    if (!_initialized || _pollInFlight) return;
    _pollInFlight = true;
    final generation = _generation;
    try {
      if (!_hasBaseline) {
        await reloadAll();
        return;
      }
      await _serial((generation) async {
        // Bound each poll to three pages. Unconsumed arrivals continue next cycle.
        for (var i = 0; i < 3; i++) {
          final page = await _fetchPage(afterId: _afterId);
          if (!_active(generation)) return;
          final known = notifications.value.map((row) => row['id']).toSet();
          final fresh = page.items.where((row) => !known.contains(row['id'])).toList();
          notifications.value = _merge(page.items);
          unreadCount.value = page.unreadCount;
          _afterId = page.afterId;
          if (fresh.isNotEmpty) {
            latestNotification.value = Map<String, dynamic>.from(fresh.last as Map);
          }
          if (!page.hasMore) break;
        }
      });
    } catch (_) {
      // Keep both data and cursor intact on failures; retry on the next cycle.
    } finally {
      if (generation == _generation) _pollInFlight = false;
    }
  }

  @visibleForTesting
  void receiveMessage(Map<String, dynamic> data) => _onWebSocketMessage(data);

  void _onWebSocketMessage(Map<String, dynamic> data) {
    if (!_initialized || data['type'] != 'notification') return;
    final payload = data['payload'];
    if (payload is! Map || payload['id'] is! int) return;
    if (notifications.value.any((row) => row['id'] == payload['id'])) return;
    if (payload['is_read'] != true) unreadCount.value++;
    notifications.value = _merge([payload]);
    latestNotification.value = Map<String, dynamic>.from(payload);
    // Do not advance the polling cursor: missing intermediate arrivals still need fetching.
  }

  Future<void> markAllRead() => _serial((generation) async {
    await ApiService.markAllNotificationsRead();
    if (!_active(generation)) return;
    notifications.value = notifications.value.map((row) => {...row as Map, 'is_read': true}).toList();
    unreadCount.value = 0;
  });

  Future<void> refresh() => _serial((generation) async {
    try {
      final count = await _fetchUnreadCount();
      if (_active(generation)) unreadCount.value = count;
    } catch (_) {}
  });

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    WebSocketService().removeListener(_onWebSocketMessage);
    ++_generation;
    _initialized = false;
    _hasBaseline = false;
    _pollInFlight = false;
    _afterId = 0;
    _beforeId = null;
    // A previous account's slow request must not block the next account's queue.
    _tail = Future.value();
    unreadCount.value = 0;
    latestNotification.value = null;
    notifications.value = [];
    hasMore.value = false;
  }
}
