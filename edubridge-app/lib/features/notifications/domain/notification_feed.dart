/// Merge pages without letting delayed server responses undo a local read.
class NotificationFeed {
  static List<dynamic> merge(List<dynamic> current, List<dynamic> incoming) {
    final byId = <int, Map<String, dynamic>>{};
    for (final row in current) {
      byId[row['id'] as int] = Map<String, dynamic>.from(row as Map);
    }
    for (final row in incoming) {
      final id = row['id'] as int;
      byId[id] = {...Map<String, dynamic>.from(row as Map),
        if (byId[id]?['is_read'] == true) 'is_read': true,
      };
    }
    return byId.values.toList()
      ..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
  }
}
