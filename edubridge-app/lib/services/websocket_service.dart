// خدمة WebSocket للدردشة والإشعارات الفورية
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config.dart';

class WebSocketService {
  // ===== Singleton Pattern =====
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // ===== المتغيرات =====
  WebSocketChannel? _channel;
  final List<void Function(Map<String, dynamic>)> _listeners = [];
  bool _isConnected = false;

  // ===== Getters =====
  bool get isConnected => _isConnected;
  WebSocketChannel? get channel => _channel;

  // ===== الاتصال بالـ WebSocket =====
  void connect(String token) {
    if (Config.wsUrl.isEmpty) {
      debugPrint('ℹ️ WebSocket is not configured for production');
      _isConnected = false;
      _channel = null;
      return;
    }

    if (_channel != null) {
      debugPrint('⚠️ WebSocket already connected');
      return;
    }

    try {
      final url = '${Config.wsUrl}?token=$token';
      debugPrint('🔌 Connecting to WebSocket');
      
      _channel = IOWebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            debugPrint('📩 WebSocket message received');
            _notifyListeners(json);
          } catch (e) {
            debugPrint('❌ Error parsing WebSocket message: $e');
          }
        },
        onDone: () {
          debugPrint('🔌 WebSocket disconnected');
          _isConnected = false;
          _channel = null;
        },
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
          _isConnected = false;
          _channel = null;
        },
      );
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      _isConnected = false;
      _channel = null;
    }
  }

  // ===== قطع الاتصال =====
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      debugPrint('🔌 WebSocket disconnected manually');
    }
  }

  // ===== إرسال رسالة =====
  void sendMessage(Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) {
      debugPrint('⚠️ Cannot send message: WebSocket not connected');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(data));
      debugPrint('📤 WebSocket message sent');
    } catch (e) {
      debugPrint('❌ Error sending WebSocket message: $e');
    }
  }

  // ===== إرسال رسالة دردشة =====
  void sendChatMessage({
    required int conversationId,
    required String content,
  }) {
    sendMessage({
      'type': 'chat',
      'conversationId': conversationId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ===== إرسال تأكيد قراءة إشعار =====
  void markNotificationRead(int notificationId) {
    sendMessage({
      'type': 'notification_read',
      'notificationId': notificationId,
    });
  }

  // ===== إدارة المستمعين =====
  void addListener(void Function(Map<String, dynamic>) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      debugPrint('👂 Listener added. Total: ${_listeners.length}');
    }
  }

  void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
    debugPrint('👂 Listener removed. Total: ${_listeners.length}');
  }

  void clearListeners() {
    _listeners.clear();
    debugPrint('👂 All listeners cleared');
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (final listener in _listeners) {
      try {
        listener(data);
      } catch (e) {
        debugPrint('❌ Error in listener: $e');
      }
    }
  }

  // ===== إعادة الاتصال =====
  void reconnect(String token) {
    disconnect();
    connect(token);
  }

  // ===== التحقق من الاتصال =====
  Future<bool> checkConnection() async {
    if (_channel == null || !_isConnected) {
      return false;
    }
    return true;
  }

  // ===== تنظيف الموارد =====
  void dispose() {
    disconnect();
    _listeners.clear();
    debugPrint('🧹 WebSocketService disposed');
  }
}