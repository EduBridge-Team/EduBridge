/// Selectable child/team data for a new case, independent of widget state.
class CaseCreationDirectory {
  const CaseCreationDirectory({
    required this.children,
    required this.users,
    required this.currentUserId,
  });

  final List<Map<String, dynamic>> children;
  final List<Map<String, dynamic>> users;
  final int? currentUserId;
}
