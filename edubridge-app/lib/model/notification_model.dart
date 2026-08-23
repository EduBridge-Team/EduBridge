// نموذج الإشعارات
class Notification {
  final int id;
  final String title;
  final String body;
  final String type; // child_added, child_evaluated, child_assigned, lesson_added
  final bool isRead;
  final int? childId;
  final String? childName;
  final int? senderId;
  final String? senderName;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.childId,
    this.childName,
    this.senderId,
    this.senderName,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      isRead: json['is_read'] ?? false,
      childId: json['child_id'],
      childName: json['child_name'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}