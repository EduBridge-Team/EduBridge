// lib/services/websocket_service.dart
// خدمة WebSocket للدردشة والإشعارات الفورية
import 'dart:async';
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
  StreamSubscription? _subscription;
  final List<void Function(Map<String, dynamic>)> _listeners = [];
  bool _isConnected = false;
  bool _manuallyClosed = false;
  String? _token;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // ===== Getters =====
  bool get isConnected => _isConnected;
  WebSocketChannel? get channel => _channel;

  /// اسم المنصة الحالية للتطبيق (web / android / ios / windows ...)
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  // ===== الاتصال بالـ WebSocket =====
  void connect(String token) {
    if (_channel != null && _isConnected) {
      debugPrint('[WS] already connected');
      return;
    }

    _manuallyClosed = false;
    _token = token;

    try {
      final url = '${Config.wsUrl}?token=$token&platform=$currentPlatform';
      debugPrint('[WS] connecting ($currentPlatform)');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        pingInterval: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 10),
      );

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;

            // نضيف المنصة إن لم تكن موجودة (معلومة مفيدة في الواجهة)
            json.putIfAbsent('platform', () => currentPlatform);

            debugPrint('[WS] message received: ${json['type']}');
            _notifyListeners(json);
          } catch (e) {
            debugPrint('[WS] error parsing message: $e');
          }
        },
        onDone: () {
          debugPrint('[WS] disconnected');
          _isConnected = false;
          _channel = null;
          _subscription = null;

          if (!_manuallyClosed) {
            _scheduleReconnect();
          }
        },
        onError: (error) {
          debugPrint('[WS] error: $error');
          _isConnected = false;
          _channel = null;
          _subscription = null;

          if (!_manuallyClosed) {
            _scheduleReconnect();
          }
        },
        cancelOnError: true,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
    } catch (e) {
      debugPrint('[WS] connection error: $e');
      _isConnected = false;
      _channel = null;
      _subscription = null;

      if (!_manuallyClosed) {
        _scheduleReconnect();
      }
    }
  }

  // ===== قطع الاتصال =====
  void disconnect() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;

    _subscription?.cancel();
    _subscription = null;

    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    debugPrint('[WS] disconnected manually');
  }

  // ===== إرسال رسالة عامة =====
  void sendMessage(Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) {
      debugPrint('[WS] cannot send message: not connected');
      return;
    }

    try {
      // نضمن وجود المنصة والمصدر في كل رسالة صادرة
      data.putIfAbsent('platform', () => currentPlatform);
      data.putIfAbsent('timestamp', () => DateTime.now().toIso8601String());

      _channel!.sink.add(jsonEncode(data));
      debugPrint('[WS] message sent: ${data['type']}');
    } catch (e) {
      debugPrint('[WS] error sending message: $e');
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
      'platform': currentPlatform,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ===== تأكيد قراءة إشعار =====
  void markNotificationRead(int notificationId) {
    sendMessage({
      'type': 'notification_read',
      'notificationId': notificationId,
      'platform': currentPlatform,
    });
  }

  // ===== إدارة المستمعين =====
  void addListener(void Function(Map<String, dynamic>) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      debugPrint('[WS] listener added. Total: ${_listeners.length}');
    }
  }

  void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
    debugPrint('[WS] listener removed. Total: ${_listeners.length}');
  }

  void clearListeners() {
    _listeners.clear();
    debugPrint('[WS] all listeners cleared');
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (final listener in List.of(_listeners)) {
      try {
        listener(data);
      } catch (e) {
        debugPrint('[WS] error in listener: $e');
      }
    }
  }

  // ===== إعادة الاتصال =====
  void reconnect([String? token]) {
    final t = token ?? _token;
    if (t == null || t.isEmpty) {
      debugPrint('[WS] cannot reconnect: missing token');
      return;
    }
    disconnect();
    connect(t);
  }

  void _scheduleReconnect() {
    if (_token == null || _manuallyClosed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WS] max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delay = _reconnectDelay * _reconnectAttempts;
    debugPrint('[WS] reconnecting in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      if (!_manuallyClosed && _token != null) {
        // نعيد الاتصال مباشرةً بدون disconnect (لأن القناة أُغلقت فعلاً)
        _channel = null;
        _isConnected = false;
        connect(_token!);
      }
    });
  }

  // ===== التحقق من الاتصال =====
  Future<bool> checkConnection() async {
    return _channel != null && _isConnected;
  }

  // ===== تنظيف الموارد =====
  void dispose() {
    disconnect();
    _listeners.clear();
    debugPrint('[WS] service disposed');
  }
}