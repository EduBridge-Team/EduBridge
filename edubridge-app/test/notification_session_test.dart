import 'dart:async';
import 'package:edubridge_app/services/notification_listener_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first notification after an empty baseline is surfaced', () async {
    var items = <dynamic>[];
    final service = NotificationListenerService(
      fetchNotifications: () async => items,
      fetchUnreadCount: () async => items.length,
    );
    await service.initialize();
    items = [{'id': 1, 'is_read': false}];
    await service.pollNow();
    expect(service.latestNotification.value?['id'], 1);
    expect(service.unreadCount.value, 1);
    service.dispose();
    expect(service.notifications.value, isEmpty);
    expect(service.latestNotification.value, isNull);
    expect(service.unreadCount.value, 0);
  });

  test('an in-flight poll cannot repopulate notification state after logout', () async {
    final response = Completer<List<dynamic>>();
    var calls = 0;
    final service = NotificationListenerService(
      fetchNotifications: () async => ++calls == 1 ? [] : response.future,
      fetchUnreadCount: () async => 0,
    );
    await service.initialize();
    final poll = service.pollNow();
    service.dispose();
    response.complete([{'id': 2, 'is_read': false}]);
    await poll;
    expect(service.notifications.value, isEmpty);
    expect(service.latestNotification.value, isNull);
    expect(service.unreadCount.value, 0);
  });
}
