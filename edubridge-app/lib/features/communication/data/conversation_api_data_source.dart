import '../../../services/api_service.dart';

/// Isolates the concrete API calls from the communication repository.
class ConversationApiDataSource {
  const ConversationApiDataSource._();

  static Future<List<dynamic>> loadConversations() =>
      ApiService.getConversations();

  static Future<List<dynamic>> availableUsers() =>
      ApiService.getConversationUsers();

  static Future<int> create(int userId, String subject) =>
      ApiService.createConversation(userId, subject);

  static Future<List<dynamic>> loadMessages(int conversationId) =>
      ApiService.getMessages(conversationId);

  static Future<void> send(int conversationId, String content) =>
      ApiService.sendMessage(conversationId: conversationId, content: content);
}
