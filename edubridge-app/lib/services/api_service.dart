// طبقة الاتصال بالـ API
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  // تخزين التوكن محلياً
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // دور المستخدم المسجّل (parent / teacher / specialist / admin)
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // اسم المستخدم المسجّل — للترحيب في الشاشة الرئيسية
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
  }

  // تسجيل الدخول — يرجّع رسالة الخطأ عند الفشل، ولا شيء عند النجاح
  static Future<String?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${Config.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await _saveToken(data['token']);
      // نحفظ الدور والاسم لتخصيص الواجهة حسب الصلاحية
      final user = data['user'];
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', user['role'] ?? '');
        await prefs.setString('name', user['name'] ?? '');
      }
      return null; // نجاح
    }
    return data['error'] ?? 'فشل تسجيل الدخول';
  }

  // إنشاء حساب
  static Future<String?> register(
      String name, String email, String password, String role) async {
    final res = await http.post(
      Uri.parse('${Config.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (res.statusCode == 201) return null;
    final data = jsonDecode(res.body);
    return data['error'] ?? 'فشل إنشاء الحساب';
  }

  // طلب جلب محمي بالتوكن — GET
  static Future<http.Response> authGet(String path) async {
    final token = await getToken();
    return http.get(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // طلب إرسال محمي بالتوكن — POST
  static Future<http.Response> authPost(String path, Map body) async {
    final token = await getToken();
    return http.post(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }
}
