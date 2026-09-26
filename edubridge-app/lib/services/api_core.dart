part of 'api_service.dart';

_apiCoreInitializeAuthState() async {
    ApiService.isAuthenticated.value = await ApiService.getToken() != null;
    final prefs = await SharedPreferences.getInstance();
    ApiService.userRole.value = prefs.getString('role');
  }

_apiCoreHandleError(Object error) {
    if (error is SocketException) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
    if (error is http.ClientException) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
    if (error is FormatException) {
      throw Exception('استجابة السيرفر غير صالحة، حاول مرة أخرى');
    }
    if (error is Exception) {
      throw error;
    }
    throw Exception('حدث خطأ غير متوقع');
  }

_apiCoreDecodeBody(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {};
    } catch (_) {
      return {};
    }
  }

_apiCoreDecodeMap(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {};
    } catch (_) {
      return {};
    }
  }

_apiCoreDecodeList(String body) {
    if (body.isEmpty) return [];
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) return decoded;
      return [];
    } catch (_) {
      return [];
    }
  }

_apiCoreExtractList(String body, String key) {
    final map = ApiService.decodeMap(body);
    final val = map[key];
    if (val is List) return val;
    return [];
  }

_apiCoreExtractMap(String body, String key) {
    final map = ApiService.decodeMap(body);
    final val = map[key];
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    return null;
  }

_apiCoreAsStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

_apiCoreSaveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    ApiService.isAuthenticated.value = true;
  }

_apiCoreGetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

_apiCoreSaveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', user['role'] ?? '');
    await prefs.setString('name', user['name'] ?? '');
    await prefs.setInt('userId', user['id'] ?? 0);
    final role = user['role'] ?? '';
    ApiService.userRole.value = role.isEmpty ? null : role;
  }

_apiCoreGetRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

_apiCoreGetName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

_apiCoreGetUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

_apiCoreLogout() async {
    WebSocketService().disconnect();
    NotificationListenerService.instance.dispose();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('userId');
    ApiService.isAuthenticated.value = false;
    ApiService.userRole.value = null;
  }

_apiCoreLogin(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = ApiService._decodeBody(res);

      if (res.statusCode == 200) {
        await ApiService._saveToken(data['token']);
        if (data['user'] != null) {
          final user = ApiService._asStringMap(data['user']);
          if (user != null) await ApiService.saveUserData(user);
        }

        final token = data['token'];
        if (token != null) {
          WebSocketService().connect(token);
          await NotificationListenerService.instance.initialize();
        }

        return null;
      }
      return data['error'] ?? 'فشل تسجيل الدخول';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

_apiCoreRegister(
      String name, String email, String password, String role,
      {String? phone, String? specialty}) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'phone': phone,
          'specialty': specialty,
        }),
      );

      final data = ApiService._decodeBody(res);

      if (res.statusCode == 201) {
        return null;
      }
      return data['error'] ?? 'فشل إنشاء الحساب';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

_apiCoreVerifyToken() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return false;

      final res = await http.get(
        Uri.parse('${Config.baseUrl}/auth/verify'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

_apiCoreAuthGet(String path) async {
    final token = await ApiService.getToken();
    return http.get(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

_apiCoreAuthPost(
      String path, Map<String, dynamic> body) async {
    final token = await ApiService.getToken();
    return http.post(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

_apiCoreAuthPut(
      String path, Map<String, dynamic> body) async {
    final token = await ApiService.getToken();
    return http.put(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

_apiCoreAuthDelete(String path) async {
    final token = await ApiService.getToken();
    return http.delete(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
