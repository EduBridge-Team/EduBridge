part of 'approval_service.dart';

Future<void> _approvalAddNotification({
    required String forRole,
    required String title,
    required String body,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ApprovalService._notificationsKey);
    final list = raw != null && raw.isNotEmpty ? jsonDecode(raw) as List : [];

    list.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'for_role': forRole,
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    await prefs.setString(ApprovalService._notificationsKey, jsonEncode(list));
  }

Future<List<Map<String, dynamic>>> _approvalGetNotificationsForRole(
      String role) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ApprovalService._notificationsKey);
    if (raw == null || raw.isEmpty) return [];
    final all = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return all.where((n) => n['for_role'] == role).toList();
  }

Future<void> _approvalMarkNotificationRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ApprovalService._notificationsKey);
    if (raw == null || raw.isEmpty) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    for (final n in list) {
      if (n['id'] == id) n['is_read'] = true;
    }
    await prefs.setString(ApprovalService._notificationsKey, jsonEncode(list));
  }

Future<int> _approvalGetUnreadCountForRole(String role) async {
    final notifs = await _approvalGetNotificationsForRole(role);
    return notifs.where((n) => n['is_read'] != true).length;
  }
