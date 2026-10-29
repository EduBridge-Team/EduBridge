import 'package:edubridge_app/features/notifications/domain/notification_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rows = <dynamic>[
    {'id': 3, 'title': 'درس جديد', 'body': 'حرف الألف', 'is_read': false},
    {'id': 2, 'title': 'Custom title', 'message': 'Teacher note', 'is_read': true},
    {'id': 1, 'title': 'Earlier', 'is_read': null},
  ];
  List<Map> apply(NotificationReadFilter status, String query) =>
      NotificationFilter.apply(rows, status: status, query: query,
        displayTitle: (row) => row['id'] == 3 ? 'New lesson' : row['title'] as String);

  test('read status and query intersect without changing source or order', () {
    expect(apply(NotificationReadFilter.unread, '').map((row) => row['id']), [3, 1]);
    expect(apply(NotificationReadFilter.read, ' NOTE ').single['id'], 2);
    expect(apply(NotificationReadFilter.unread, 'note'), isEmpty);
    expect(rows[0]['is_read'], false);
    expect(() => apply(NotificationReadFilter.all, '').clear(), throwsUnsupportedError);
  });
  test('search matches translated titles, original titles and authored text', () {
    for (final query in [' New LESSON ', 'درس', 'الألف']) {
      expect(apply(NotificationReadFilter.all, query).single['id'], 3);
    }
    expect(apply(NotificationReadFilter.all, 'teacher').single['id'], 2);
    expect(apply(NotificationReadFilter.all, '3'), isEmpty);
  });
}
