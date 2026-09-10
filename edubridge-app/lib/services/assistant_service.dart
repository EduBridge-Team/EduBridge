import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AssistantMessage {
  final String role;
  final String content;

  const AssistantMessage({required this.role, required this.content});

  bool get isUser => role == 'user';

  Map<String, String> toJson() => {'role': role, 'content': content};

  factory AssistantMessage.fromJson(Map<String, dynamic> json) =>
      AssistantMessage(
        role: json['role'] == 'user' ? 'user' : 'assistant',
        content: (json['content'] ?? '').toString(),
      );
}

class AssistantService {
  static const _historyKeyPrefix = 'noor_assistant_history_v1';
  static const _maxStoredMessages = 20;

  static Future<String> _historyKey() async {
    final userId = await ApiService.getUserId() ?? 0;
    return '${_historyKeyPrefix}_$userId';
  }

  static Future<List<AssistantMessage>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _historyKey();
    final raw = prefs.getString(key);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map((item) => AssistantMessage.fromJson(
              Map<String, dynamic>.from(item)))
          .where((message) => message.content.trim().isNotEmpty)
          .toList();
    } catch (_) {
      await prefs.remove(key);
      return [];
    }
  }

  static Future<void> saveHistory(List<AssistantMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _historyKey();
    final recent = messages.length > _maxStoredMessages
        ? messages.sublist(messages.length - _maxStoredMessages)
        : messages;
    await prefs.setString(
      key,
      jsonEncode(recent.map((message) => message.toJson()).toList()),
    );
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _historyKey());
  }

  static Future<String> ask({
    required List<AssistantMessage> messages,
    String? context,
  }) async {
    final recent = messages.length > 12
        ? messages.sublist(messages.length - 12)
        : messages;
    final response = await ApiService.authPost('/assistant/chat', {
      'messages': recent.map((message) => message.toJson()).toList(),
      if (context != null && context.trim().isNotEmpty)
        'context': context.length > 1200 ? context.substring(0, 1200) : context,
    });

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // A friendly fallback is thrown below.
    }

    if (response.statusCode == 200 && data['reply'] is String) {
      return (data['reply'] as String).trim();
    }

    throw Exception(data['error'] ?? 'تعذّر التواصل مع نور الآن.');
  }
}
