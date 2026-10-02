class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.hasMore,
    this.beforeId,
    required this.afterId,
  });

  final List<dynamic> items;
  final int unreadCount;
  final bool hasMore;
  final int? beforeId;
  final int afterId;

  factory NotificationPage.fromJson(Map<String, dynamic> data) {
    final rows = data['notifications'];
    final meta = data['pagination'];
    if (rows is! List || meta is! Map ||
        data['unread_count'] is! int || meta['has_more'] is! bool ||
        meta['next_after_id'] is! int ||
        (meta['next_before_id'] != null && meta['next_before_id'] is! int) ||
        rows.any((row) => row is! Map || row['id'] is! int)) {
      throw const FormatException('Invalid notification page');
    }
    return NotificationPage(
      items: rows,
      unreadCount: data['unread_count'] as int,
      hasMore: meta['has_more'] as bool,
      beforeId: meta['next_before_id'] as int?,
      afterId: meta['next_after_id'] as int,
    );
  }
}
