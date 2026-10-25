/// Determines which children and care-team members can be selected for a case.
abstract final class CaseTeamPolicy {
  static Set<int> _ids(
    Map child,
    Iterable<String> singles,
    Iterable<String> lists,
  ) {
    final ids = <int>{};
    void add(Object? value) {
      final id = value is int
          ? value
          : value is String
          ? int.tryParse(value)
          : null;
      if (id != null) ids.add(id);
    }

    for (final key in singles) {
      add(child[key]);
    }
    for (final key in lists) {
      final values = child[key];
      if (values is List) values.forEach(add);
    }
    return ids;
  }

  static Set<int> specialistIds(Map child) => _ids(
    child,
    ['specialist_id', 'assigned_specialist_id'],
    ['specialist_ids', 'assigned_specialist_ids'],
  );

  static Set<int> teamIds(Map child) => _ids(
    child,
    ['assigned_teacher_id', 'specialist_id', 'assigned_specialist_id'],
    [
      'teacher_ids',
      'assigned_teacher_ids',
      'specialist_ids',
      'assigned_specialist_ids',
    ],
  );

  static List<Map<String, dynamic>> assignedChildren(
    List<Map<String, dynamic>> children, {
    required String? role,
    required int? userId,
  }) => children.where((child) {
    if (role == 'admin') return true;
    // A missing local identity must not expose unassigned children to a teacher.
    if (userId == null) return false;
    if (role == 'teacher') {
      return child['assigned_teacher_id']?.toString() == userId.toString();
    }
    if (role == 'specialist') return specialistIds(child).contains(userId);
    return false;
  }).toList();

  static List<Map<String, dynamic>> eligibleUsers(
    List<Map<String, dynamic>> users,
  ) => users
      .where(
        (user) => user['role'] == 'teacher' || user['role'] == 'specialist',
      )
      .toList();

  static List<Map<String, dynamic>> teamFor(
    Map child,
    List<Map<String, dynamic>> users,
  ) {
    final ids = teamIds(child);
    return eligibleUsers(users)
        .where((user) => ids.contains(user['id']))
        .toList();
  }
}
