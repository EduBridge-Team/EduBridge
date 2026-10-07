import 'package:edubridge_app/features/communication/data/conversation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message delivery retains conversation identity and composer content', () async {
    final calls = <Object>[];
    final repository = ConversationRepository(
      send: (id, content) async { calls.addAll([id, content]); },
      messages: (id) async { calls.add(id); return [{'content': 'نص'}]; },
    );
    await repository.send(42, 'رسالة مع رموز 👋');
    final messages = await repository.loadMessages(42);
    expect(calls, [42, 'رسالة مع رموز 👋', 42]);
    expect(messages.single['content'], 'نص');
  });
  test('permission errors propagate unchanged for the existing screen handler', () async {
    final failure = Exception('not allowed');
    final repository = ConversationRepository(users: () async => throw failure);
    await expectLater(repository.availableUsers(), throwsA(same(failure)));
  });
  test('send failure cannot be mistaken for successful delivery', () async {
    final failure = Exception('offline');
    final repository = ConversationRepository(send: (_, __) async => throw failure);
    await expectLater(repository.send(1, 'message'), throwsA(same(failure)));
  });
}
