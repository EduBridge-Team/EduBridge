import 'package:edubridge_app/features/notifications/domain/notification_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('page overlap keeps unique IDs sorted newest first', () {
    final result = NotificationFeed.merge([
      {'id': 3, 'is_read': false}, {'id': 1, 'is_read': false},
    ], [
      {'id': 2, 'is_read': false}, {'id': 3, 'title': 'new', 'is_read': false},
    ]);
    expect(result.map((row) => row['id']), [3, 2, 1]);
    expect(result.first['title'], 'new');
  });
  test('delayed response preserves read state but updates other fields', () {
    final result = NotificationFeed.merge([
      {'id': 1, 'is_read': true, 'title': 'old'},
    ], [{'id': 1, 'is_read': false, 'title': 'updated'}]);
    expect(result.single['is_read'], true);
    expect(result.single['title'], 'updated');
  });
  test('duplicate rows in one page cannot undo read state', () {
    final result = NotificationFeed.merge([], [
      {'id': 1, 'is_read': true}, {'id': 1, 'is_read': false},
    ]);
    expect(result.single['is_read'], true);
  });
  test('merging does not mutate caller records', () {
    final original = {'id': 1, 'is_read': true};
    final incoming = {'id': 1, 'is_read': false};
    final result = NotificationFeed.merge([original], [incoming]);
    result.single['title'] = 'changed';
    expect(original.containsKey('title'), false);
    expect(incoming, {'id': 1, 'is_read': false});
  });
}
