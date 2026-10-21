import 'conversation_api_data_source.dart';

/// Communication data access, leaving composer and navigation in the widgets.
class ConversationRepository {
  ConversationRepository({
    Future<List<dynamic>> Function()? conversations,
    Future<List<dynamic>> Function()? users,
    Future<int> Function(int, String)? create,
    Future<List<dynamic>> Function(int)? messages,
    Future<void> Function(int, String)? send,
  })  : _conversations = conversations ?? ConversationApiDataSource.loadConversations,
        _users = users ?? ConversationApiDataSource.availableUsers,
        _create = create ?? ConversationApiDataSource.create,
        _messages = messages ?? ConversationApiDataSource.loadMessages,
        _send = send ?? ConversationApiDataSource.send;

  final Future<List<dynamic>> Function() _conversations;
  final Future<List<dynamic>> Function() _users;
  final Future<int> Function(int, String) _create;
  final Future<List<dynamic>> Function(int) _messages;
  final Future<void> Function(int, String) _send;

  Future<List<dynamic>> loadConversations() => _conversations();
  Future<List<dynamic>> availableUsers() => _users();
  Future<int> create(int userId, String subject) => _create(userId, subject);
  Future<List<dynamic>> loadMessages(int conversationId) => _messages(conversationId);
  Future<void> send(int conversationId, String content) => _send(conversationId, content);
}
