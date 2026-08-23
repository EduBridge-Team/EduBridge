// خدمة WebSocket للدردشة والإشعارات الفورية
import 'dart:convert';
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
    if (_channel != null) {
      print('⚠️ WebSocket already connected');
      return;
    }

    try {
      final url = '${Config.wsUrl}?token=$token';
      print('🔌 Connecting to WebSocket: $url');
      
      _channel = IOWebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            print('📩 WebSocket message received: $json');
            _notifyListeners(json);
          } catch (e) {
            print('❌ Error parsing WebSocket message: $e');
          }
        },
        onDone: () {
          print('🔌 WebSocket disconnected');
          _isConnected = false;
          _channel = null;
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
          _channel = null;
        },
      );
    } catch (e) {
      print('❌ WebSocket connection error: $e');
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
      print('🔌 WebSocket disconnected manually');
    }
  }

  // ===== إرسال رسالة =====
  void sendMessage(Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) {
      print('⚠️ Cannot send message: WebSocket not connected');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(data));
      print('📤 WebSocket message sent: $data');
    } catch (e) {
      print('❌ Error sending WebSocket message: $e');
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
      print('👂 Listener added. Total: ${_listeners.length}');
    }
  }

  void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
    print('👂 Listener removed. Total: ${_listeners.length}');
  }

  void clearListeners() {
    _listeners.clear();
    print('👂 All listeners cleared');
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (final listener in _listeners) {
      try {
        listener(data);
      } catch (e) {
        print('❌ Error in listener: $e');
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
    print('🧹 WebSocketService disposed');
  }
}