enum NotificationReadFilter { all, unread, read }

/// Filters only already-authorized, loaded rows; never changes feed cursors.
class NotificationFilter {
  static List<Map> apply(
    Iterable<dynamic> rows, {
    required NotificationReadFilter status,
    required String query,
    required String Function(Map) displayTitle,
  }) {
    final needle = query.trim().toLowerCase();
    return List<Map>.unmodifiable(rows.whereType<Map>().where((row) {
      final read = row['is_read'] == true;
      if (status == NotificationReadFilter.unread && read) return false;
      if (status == NotificationReadFilter.read && !read) return false;
      if (needle.isEmpty) return true;
      return [displayTitle(row), row['title'], row['body'], row['message']]
          .where((value) => value != null)
          .any((value) => value.toString().toLowerCase().contains(needle));
    }));
  }
}
