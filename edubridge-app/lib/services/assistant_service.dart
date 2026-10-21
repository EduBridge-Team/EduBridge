import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:image_picker/image_picker.dart';

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
  static const _maxContextLength = 4000;

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

  /// Images are submitted on demand and are never added to persisted chat history.
  static Future<String> analyzeImage({
    required XFile image,
    required String question,
  }) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty || bytes.length > 3 * 1024 * 1024) {
      throw Exception('حجم الصورة يجب ألا يتجاوز 3 ميجابايت.');
    }
    final extension = image.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw Exception('اختر صورة JPEG أو PNG أو WebP.');
    }
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) throw Exception('يرجى تسجيل الدخول أولاً.');
    final request = http.MultipartRequest(
      'POST', Uri.parse('${Config.baseUrl}/assistant/vision/analyze'),
    )..headers['Authorization'] = 'Bearer $token';
    final trimmedQuestion = question.trim();
    request.fields['question'] = trimmedQuestion.isEmpty
        ? 'اشرح محتوى هذه الصورة التعليمية.'
        : trimmedQuestion.substring(
            0, trimmedQuestion.length > 1200 ? 1200 : trimmedQuestion.length);
    request.files.add(http.MultipartFile.fromBytes(
      'image', bytes, filename: image.name,
    ));
    final response = await request.send().timeout(const Duration(seconds: 45));
    final data = ApiService.decodeMap(await response.stream.bytesToString());
    if (response.statusCode == 200 && data['reply'] is String) {
      return (data['reply'] as String).trim();
    }
    throw Exception(data['error'] ?? 'تعذّر تحليل الصورة.');
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
        'context': context.length > _maxContextLength
            ? context.substring(0, _maxContextLength)
            : context,
    });

    final data = ApiService.decodeMap(response.body);

    if (response.statusCode == 200 && data['reply'] is String) {
      return (data['reply'] as String).trim();
    }

    throw Exception(data['error'] ?? 'تعذّر التواصل مع نور الآن.');
  }
}
