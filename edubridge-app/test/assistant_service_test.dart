import 'package:edubridge_app/services/assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'userId': 42});
  });

  test('assistant messages serialize safely', () {
    const message = AssistantMessage(role: 'user', content: 'اشرح الدرس');

    final restored = AssistantMessage.fromJson(message.toJson());

    expect(restored.role, 'user');
    expect(restored.content, 'اشرح الدرس');
    expect(restored.isUser, isTrue);
  });

  test('chat history is stored for the current account', () async {
    const messages = [
      AssistantMessage(role: 'user', content: 'مرحباً'),
      AssistantMessage(role: 'assistant', content: 'أهلاً بك'),
    ];

    await AssistantService.saveHistory(messages);
    final restored = await AssistantService.loadHistory();

    expect(restored, hasLength(2));
    expect(restored.last.content, 'أهلاً بك');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('noor_assistant_history_v1_42'), isTrue);
  });
}
