import 'dart:async';
import 'package:edubridge_app/services/notification_listener_service.dart';
import 'package:edubridge_app/services/notification_page.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationPage page(List<int> ids, {int count = 0, bool more = false, int? before, int? after}) => NotificationPage(
  items: ids.map((id) => {'id': id, 'is_read': false}).toList(),
  unreadCount: count, hasMore: more, beforeId: before,
  afterId: after ?? (ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)),
);

void main() {
  test('first notification after an empty baseline is surfaced', () async {
    var ids = <int>[];
    final service = NotificationListenerService(
      fetchPage: ({beforeId, afterId}) async => page(ids, count: ids.length),
      fetchUnreadCount: () async => ids.length,
    );
    await service.initialize();
    ids = [1];
    await service.pollNow();
    expect(service.latestNotification.value?['id'], 1);
    expect(service.unreadCount.value, 1);
    service.dispose();
    expect(service.notifications.value, isEmpty);
    expect(service.latestNotification.value, isNull);
    expect(service.unreadCount.value, 0);
  });

  test('in-flight poll cannot repopulate state after logout', () async {
    final response = Completer<NotificationPage>();
    var calls = 0;
    final service = NotificationListenerService(fetchPage: ({beforeId, afterId}) async {
      if (++calls == 1) return page([]);
      return response.future;
    });
    await service.initialize();
    final poll = service.pollNow();
    await Future<void>.delayed(Duration.zero);
    service.dispose();
    response.complete(page([2], count: 1));
    await poll;
    expect(service.notifications.value, isEmpty);
    expect(service.latestNotification.value, isNull);
    expect(service.unreadCount.value, 0);
  });

  test('older-page failure preserves items and cursor for retry', () async {
    var fail = true;
    final cursors = <int?>[];
    final service = NotificationListenerService(fetchPage: ({beforeId, afterId}) async {
      cursors.add(beforeId);
      if (beforeId == null) return page([5, 4], count: 50, more: true, before: 4);
      if (fail) throw Exception('offline');
      return page([4, 3], count: 50);
    });
    await service.initialize();
    expect(service.unreadCount.value, 50);
    await expectLater(service.loadMore(), throwsException);
    expect(service.notifications.value.map((row) => row['id']), [5, 4]);
    expect(service.hasMore.value, true);
    fail = false;
    await service.loadMore();
    expect(cursors, [null, 4, 4]);
    expect(service.notifications.value.map((row) => row['id']), [5, 4, 3]);
    expect(service.hasMore.value, false);
    service.dispose();
  });

  test('delta backlog drains over bounded polls without gaps and retains older pages', () async {
    final cursors = <int>[];
    final service = NotificationListenerService(fetchPage: ({beforeId, afterId}) async {
      if (afterId == null) return page([2, 1]);
      cursors.add(afterId);
      return page([afterId + 1], after: afterId + 1, more: afterId < 6, count: 7);
    });
    await service.initialize();
    await service.pollNow();
    expect(cursors, [2, 3, 4]);
    await service.pollNow();
    expect(cursors, [2, 3, 4, 5, 6]);
    expect(service.notifications.value.map((row) => row['id']), [7, 6, 5, 4, 3, 2, 1]);
    expect(service.latestNotification.value?['id'], 7);
    service.dispose();
  });

  test('delayed page cannot undo a local read', () async {
    final service = NotificationListenerService(fetchPage: ({beforeId, afterId}) async => page([1], after: 1));
    await service.initialize();
    service.notifications.value = [{'id': 1, 'is_read': true}];
    await service.pollNow();
    expect(service.notifications.value.single['is_read'], true);
    service.dispose();
  });

  test('failed initial history retries as baseline without old-notification toast', () async {
    var fail = true;
    final service = NotificationListenerService(fetchPage: ({beforeId, afterId}) async {
      if (fail) throw Exception('offline');
      expect(afterId, isNull);
      return page([10, 9]);
    });
    await service.initialize();
    fail = false;
    await service.pollNow();
    expect(service.notifications.value.map((row) => row['id']), [10, 9]);
    expect(service.latestNotification.value, isNull);
    service.dispose();
  });

  test('in-flight older page cannot repopulate after logout', () async {
    final response = Completer<NotificationPage>();
    final service = NotificationListenerService(fetchPage: ({beforeId, afterId}) async {
      if (beforeId == null) return page([5], more: true, before: 5);
      return response.future;
    });
    await service.initialize();
    final pending = service.loadMore();
    await Future<void>.delayed(Duration.zero);
    service.dispose();
    response.complete(page([4]));
    await pending;
    expect(service.notifications.value, isEmpty);
    expect(service.hasMore.value, false);
  });

  test('duplicate websocket arrivals do not skip intermediate polling deliveries', () async {
    final service = NotificationListenerService(fetchPage: ({beforeId, afterId}) async {
      if (afterId == null) return page([2, 1], count: 2);
      expect(afterId, 2);
      return page([3, 4, 5], count: 5, after: 5);
    });
    await service.initialize();
    final message = {'type': 'notification', 'payload': {'id': 5, 'is_read': false}};
    service.receiveMessage(message);
    service.receiveMessage(message);
    expect(service.unreadCount.value, 3);
    await service.pollNow();
    expect(service.notifications.value.map((row) => row['id']), [5, 4, 3, 2, 1]);
    expect(service.unreadCount.value, 5);
    service.dispose();
  });

  test('malformed page fails instead of silently replacing notification state', () {
    expect(() => NotificationPage.fromJson({'notifications': []}), throwsFormatException);
    final parsed = NotificationPage.fromJson({
      'notifications': [], 'unread_count': 99,
      'pagination': {'has_more': false, 'next_before_id': null, 'next_after_id': 10},
    });
    expect(parsed.unreadCount, 99);
    expect(parsed.afterId, 10);
  });
}
