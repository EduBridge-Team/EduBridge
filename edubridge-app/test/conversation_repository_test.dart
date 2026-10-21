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

  test('repository forwards all operations to injected data functions', () async {
    final operations = <String>[];
    final repository = ConversationRepository(
      conversations: () async {
        operations.add('conversations');
        return [1];
      },
      users: () async {
        operations.add('users');
        return [2];
      },
      create: (id, subject) async {
        operations.add('create:$id:$subject');
        return 9;
      },
      messages: (id) async {
        operations.add('messages:$id');
        return [3];
      },
      send: (id, content) async {
        operations.add('send:$id:$content');
      },
    );

    expect(await repository.loadConversations(), [1]);
    expect(await repository.availableUsers(), [2]);
    expect(await repository.create(4, 'topic'), 9);
    expect(await repository.loadMessages(9), [3]);
    await repository.send(9, 'hello');
    expect(operations, [
      'conversations',
      'users',
      'create:4:topic',
      'messages:9',
      'send:9:hello',
    ]);
  });
}
