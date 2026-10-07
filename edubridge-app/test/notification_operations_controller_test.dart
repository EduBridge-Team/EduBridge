import 'dart:async';
import 'package:edubridge_app/features/notifications/presentation/notification_operations_controller.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationOperationsController controller({Future<void> Function()? reload,
  Future<void> Function()? more, Future<void> Function()? mark,
  Future<void> Function()? refresh}) => NotificationOperationsController(
    reload: reload ?? () async {}, loadMore: more ?? () async {},
    markAllRead: mark ?? () async {}, refresh: refresh ?? () async {});

void main() {
  test('older-page load excludes mark-all and repeated pagination', () async {
    final pending = Completer<void>();
    var calls = 0;
    var marks = 0;
    final state = controller(more: () { calls++; return pending.future; }, mark: () async { marks++; });
    addTearDown(state.dispose);
    final request = state.loadMore();
    expect(state.loadingMore, true);
    expect(await state.loadMore(), false);
    expect(await state.markAllRead(), false);
    pending.complete();
    expect(await request, true);
    expect(calls, 1);
    expect(marks, 0);
    expect(state.loadingMore, false);
  });
  test('mark-all excludes pagination and refreshes only after marking', () async {
    final pending = Completer<void>();
    final events = <String>[];
    final state = controller(mark: () { events.add('mark'); return pending.future; },
      refresh: () async { events.add('refresh'); });
    addTearDown(state.dispose);
    final request = state.markAllRead();
    expect(await state.loadMore(), false);
    expect(await state.markAllRead(), false);
    pending.complete();
    expect(await request, true);
    expect(events, ['mark', 'refresh']);
    expect(state.markingAll, false);
  });
  test('failed pagination resets busy state and permits retry', () async {
    var fail = true;
    final state = controller(more: () async { if (fail) throw Exception('offline'); });
    addTearDown(state.dispose);
    await expectLater(state.loadMore(), throwsException);
    expect(state.loadingMore, false);
    fail = false;
    expect(await state.loadMore(), true);
  });
  test('disposed mark operation does not trigger refresh or notifications', () async {
    final pending = Completer<void>();
    var refreshes = 0;
    var updates = 0;
    final state = controller(mark: () => pending.future, refresh: () async { refreshes++; });
    state.addListener(() => updates++);
    final request = state.markAllRead();
    state.dispose();
    pending.complete();
    expect(await request, false);
    expect(refreshes, 0);
    expect(updates, 1);
  });
  test('obsolete reload failure cannot replace newer successful state', () async {
    final pending = Completer<void>();
    var calls = 0;
    final state = controller(reload: () => ++calls == 1 ? pending.future : Future.value());
    addTearDown(state.dispose);
    final first = state.reload();
    await state.reload();
    pending.completeError(Exception());
    await first;
    expect(state.loading, false);
    expect(state.error, isNull);
  });
}
