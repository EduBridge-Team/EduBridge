import 'package:edubridge_app/features/notifications/presentation/notification_center_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('filter, search, empty pagination and read updates $language $width at 2x', (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var rows = <dynamic>[
          {'id': 2, 'title': 'درس جديد', 'is_read': false},
          {'id': 1, 'title': 'Custom note', 'is_read': true},
        ];
        var moreCalls = 0;
        var markCalls = 0;
        late StateSetter update;
        await tester.pumpWidget(curriculumHost(Scaffold(body: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return NotificationCenterView(
              rows: rows, hasMore: true, loadingMore: false, markingAll: false,
              unreadCount: rows.where((row) => row['is_read'] != true).length,
              onRefresh: () async {}, onLoadMore: () => moreCalls++,
              onMarkAllRead: () {
                markCalls++;
                setState(() => rows = rows.map((row) => {...row as Map, 'is_read': true}).toList());
              },
              displayTitle: (row) => row['title'] as String,
              tileBuilder: (row) => Text(row['title'] as String,
                  key: ValueKey('notification-row-${row['id']}')),
            );
          },
        )), language));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('notification-filter-unread')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('notification-row-2')), findsOneWidget);
        expect(find.byKey(const ValueKey('notification-row-1')), findsNothing);
        await tester.enterText(find.byKey(const ValueKey('notification-search')), 'absent');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('notification-empty')), findsOneWidget);
        final older = find.byKey(const ValueKey('notification-load-older'));
        await tester.ensureVisible(older); await tester.tap(older); await tester.pumpAndSettle();
        expect(moreCalls, 1);
        update(() => rows = [...rows, {'id': 0, 'title': 'absent match', 'is_read': false}]);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('notification-row-0')), findsOneWidget);
        final mark = find.byKey(const ValueKey('notification-mark-all'));
        await tester.ensureVisible(mark); await tester.tap(mark); await tester.pumpAndSettle();
        expect(markCalls, 1);
        expect(find.byKey(const ValueKey('notification-empty')), findsOneWidget);
        expect(find.byKey(const ValueKey('notification-row-0')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
