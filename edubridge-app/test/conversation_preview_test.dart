import 'package:edubridge_app/features/communication/models/conversation_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps real conversation card fields without altering their values', () {
    final preview = ConversationPreview.fromMap({
      'id': '42',
      'other_user_name': 'أحمد',
      'other_user_role': 'teacher',
      'subject': 'محادثة',
      'last_message': 'مرحبا',
      'last_message_at': '2026-10-21T12:30:00',
    });

    expect(preview.id, 42);
    expect(preview.otherUserName, 'أحمد');
    expect(preview.otherUserRole, 'teacher');
    expect(preview.subject, 'محادثة');
    expect(preview.lastMessage, 'مرحبا');
    expect(preview.lastMessageAt, DateTime(2026, 10, 21, 12, 30));
  });

  test('missing and malformed optional fields remain display-safe', () {
    final empty = ConversationPreview.fromMap({});
    expect(empty.id, isNull);
    expect(empty.otherUserName, '');
    expect(empty.lastMessage, '');
    expect(empty.lastMessageAt, isNull);

    final invalid = ConversationPreview.fromMap({
      'id': 'unknown',
      'last_message_at': 'invalid-date',
    });
    expect(invalid.id, isNull);
    expect(invalid.lastMessageAt, isNull);
  });
}
