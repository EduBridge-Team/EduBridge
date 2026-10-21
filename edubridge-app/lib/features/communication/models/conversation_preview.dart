/// Read-only view of the fields used by conversation list cards.
///
/// Decoding preserves the existing screen's tolerant string conversion and
/// does not alter the wire payload or the repository's public API.
class ConversationPreview {
  const ConversationPreview({
    required this.id,
    required this.otherUserName,
    required this.otherUserRole,
    required this.subject,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  final int? id;
  final String otherUserName;
  final String otherUserRole;
  final String subject;
  final String lastMessage;
  final DateTime? lastMessageAt;

  factory ConversationPreview.fromMap(Map conversation) {
    String text(Object? value) => value?.toString() ?? '';
    final dateValue = conversation['last_message_at'];
    return ConversationPreview(
      id: int.tryParse(text(conversation['id'])),
      otherUserName: text(conversation['other_user_name']),
      otherUserRole: text(conversation['other_user_role']),
      subject: text(conversation['subject']),
      lastMessage: text(conversation['last_message']),
      lastMessageAt: dateValue == null
          ? null
          : DateTime.tryParse(dateValue.toString()),
    );
  }
}
