import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_service.dart';
import 'notification_listener_service.dart';
import 'token_store.dart';
import 'websocket_service.dart';

class GoogleRoleLoginService {
  GoogleRoleLoginService._();

  static const allowedRoles = <String>{'parent', 'teacher', 'specialist'};

  static Future<String?> login(String idToken, {required String role}) async {
    if (!allowedRoles.contains(role)) {
      return 'اختر نوع حساب صالحاً';
    }

    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken, 'role': role}),
      );

      final data = ApiService.decodeMap(res.body);
      if (res.statusCode == 200) {
        final token = data['token'];
        if (token is! String || token.isEmpty) {
          return 'تعذّر إنشاء جلسة الدخول عبر Google';
        }

        await TokenStore.instance.save(token);
        ApiService.isAuthenticated.value = true;

        final rawUser = data['user'];
        if (rawUser is Map) {
          await ApiService.saveUserData(Map<String, dynamic>.from(rawUser));
        }

        WebSocketService().connect(token);
        await NotificationListenerService.instance.initialize();
        return null;
      }

      return data['error']?.toString() ??
          data['message']?.toString() ??
          'فشل تسجيل الدخول عبر Google';
    } on TokenStorageException catch (e) {
      return e.toString();
    } catch (_) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }
}
