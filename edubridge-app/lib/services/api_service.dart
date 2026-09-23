// lib/services/api_service.dart
// طبقة الاتصال بالـ API - كاملة ومتكاملة مع جميع التحديثات

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'websocket_service.dart';
import 'notification_listener_service.dart';

class ApiService {
  static final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);
  static final ValueNotifier<String?> userRole = ValueNotifier<String?>(null);

  static Future<void> initializeAuthState() async {
    isAuthenticated.value = await getToken() != null;
    final prefs = await SharedPreferences.getInstance();
    userRole.value = prefs.getString('role');
  }

  // ═══════════════════════════════════════════════════════════
  //  معالج أخطاء موحّد
  // ═══════════════════════════════════════════════════════════
  static Never _handleError(Object error) {
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

  static Map<String, dynamic> _decodeBody(http.Response res) {
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

  // ===== دوال التخزين المحلي =====

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    isAuthenticated.value = true;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', user['role'] ?? '');
    await prefs.setString('name', user['name'] ?? '');
    await prefs.setInt('userId', user['id'] ?? 0);
    final role = user['role'] ?? '';
    userRole.value = role.isEmpty ? null : role;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<void> logout() async {
    WebSocketService().disconnect();
    NotificationListenerService.instance.dispose();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('userId');
    isAuthenticated.value = false;
    userRole.value = null;
  }

  // ===== دوال المصادقة (Auth) =====

  static Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = _decodeBody(res);

      if (res.statusCode == 200) {
        await _saveToken(data['token']);
        if (data['user'] != null) {
          await saveUserData(data['user']);
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

  static Future<String?> register(
      String name, String email, String password, String role,
      {String? phone,String? specialty}) async {
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

      final data = _decodeBody(res);

      if (res.statusCode == 201) {
        return null;
      }
      return data['error'] ?? 'فشل إنشاء الحساب';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

  static Future<bool> verifyToken() async {
    try {
      final token = await getToken();
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

  // ===== دوال الطلبات المحمية =====

  static Future<http.Response> authGet(String path) async {
    final token = await getToken();
    return http.get(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> authPost(
      String path, Map<String, dynamic> body) async {
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

  static Future<http.Response> authPut(
      String path, Map<String, dynamic> body) async {
    final token = await getToken();
    return http.put(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> authDelete(String path) async {
    final token = await getToken();
    return http.delete(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // ===== دوال الأطفال (Children) =====

  static Future<Map<String, dynamic>?> getChildren() async {
    try {
      final res = await authGet('/children');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data;
      }
      throw Exception(data['error'] ?? 'فشل جلب الأطفال');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<Map<String, dynamic>?> addChild({
    required String name,
    required int age,
    String? disabilityType,
    String? disabilityDescription,
    String? specialNeeds,
    String? preferredLearningStyle,
    List<String>? strengths,
    List<String>? challenges,
    File? idCardFile,
    File? birthCertFile,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('${Config.baseUrl}/children');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['age'] = age.toString();
      if (disabilityType != null) {
        request.fields['disability_type'] = disabilityType;
      }
      if (disabilityDescription != null) {
        request.fields['disability_description'] = disabilityDescription;
      }
      if (specialNeeds != null) {
        request.fields['special_needs'] = specialNeeds;
      }
      if (preferredLearningStyle != null) {
        request.fields['preferred_learning_style'] =
            preferredLearningStyle;
      }
      if (strengths != null && strengths.isNotEmpty) {
        request.fields['strengths'] = jsonEncode(strengths);
      }
      if (challenges != null && challenges.isNotEmpty) {
        request.fields['challenges'] = jsonEncode(challenges);
      }

      if (idCardFile != null && await idCardFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'id_card', idCardFile.path),
        );
      }
      if (birthCertFile != null && await birthCertFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'birth_certificate', birthCertFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = responseBody.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data['child'];
      }
      throw Exception(data['error'] ?? 'فشل إضافة الطفل');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<Map<String, dynamic>?> getChildDetails(int childId) async {
    try {
      final res = await authGet('/children/$childId');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['child'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateChild(
      int childId, Map<String, dynamic> data) async {
    try {
      final res = await authPut('/children/$childId', data);
      final responseData = _decodeBody(res);
      if (res.statusCode == 200) {
        return responseData['child'];
      }
      throw Exception(responseData['error'] ?? 'فشل تحديث بيانات الطفل');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<List<dynamic>> getChildLessons(int childId) async {
    try {
      final res = await authGet('/children/$childId/lessons');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== دوال التقييم (Evaluations) =====

  static Future<Map<String, dynamic>?> evaluateChild({
    required int childId,
    required String evaluationType,
    required String cognitiveAssessment,
    required String motorAssessment,
    required String emotionalAssessment,
    required String socialAssessment,
    required String recommendations,
    int? assignedTeacherId,
    required String educationalPlan,
    required List<String> teachingMethods,
  }) async {
    try {
      final res = await authPost('/evaluations/child/$childId', {
        'evaluation_type': evaluationType,
        'cognitive_assessment': cognitiveAssessment,
        'motor_assessment': motorAssessment,
        'emotional_assessment': emotionalAssessment,
        'social_assessment': socialAssessment,
        'recommendations': recommendations,
        'assigned_teacher_id': assignedTeacherId,
        'educational_plan': educationalPlan,
        'teaching_methods': teachingMethods,
      });

      final data = _decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return data['evaluation'];
      }
      throw Exception(data['error'] ?? 'فشل تقييم الطفل');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<List<dynamic>> getChildEvaluations(int childId) async {
    try {
      final res = await authGet('/evaluations/child/$childId');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['evaluations'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getLessons() async {
    try {
      final res = await authGet('/lessons');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLessonDetails(
      int lessonId) async {
    try {
      final res = await authGet('/lessons/$lessonId');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['lesson'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ✅ مُحدَّثة: يقبل الملفات الجديدة (ترجمات، لغة إشارة، وصف صوتي)
  static Future<Map<String, dynamic>?> createLessonWithMedia({
    required String title,
    String? content,
    int? disabilityTypeId,
    List<File>? imageFiles,
    File? videoFile,
    File? audioFile,
    File? captionFile,
    File? signLanguageFile,
    String? audioDescription,
    String? targetType,
    List<int>? targetChildIds,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('${Config.baseUrl}/lessons');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title;

      if (content != null && content.trim().isNotEmpty) {
        request.fields['content'] = content.trim();
      }
      if (disabilityTypeId != null) {
        request.fields['disability_type_id'] = disabilityTypeId.toString();
      }
      if (targetType != null) {
        request.fields['target_type'] = targetType;
      }
      if (targetChildIds != null && targetChildIds.isNotEmpty) {
        request.fields['target_child_ids'] = jsonEncode(targetChildIds);
      }
      if (audioDescription != null && audioDescription.trim().isNotEmpty) {
        request.fields['audio_description'] = audioDescription.trim();
      }

      // ✅ صور الدرس (يمكن رفع أكثر من صورة)
      if (imageFiles != null) {
        for (final image in imageFiles) {
          if (await image.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath('images[]', image.path),
            );
          }
        }
      }

      // ✅ الملفات الأساسية
      if (videoFile != null && await videoFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('video', videoFile.path),
        );
      }
      if (audioFile != null && await audioFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('audio', audioFile.path),
        );
      }

      // ✅ الملفات الجديدة
      if (captionFile != null && await captionFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('caption', captionFile.path),
        );
      }
      if (signLanguageFile != null && await signLanguageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'sign_language', signLanguageFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = responseBody.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode == 201) {
        return data['lesson'];
      }
      throw Exception(data['error'] ?? 'فشل إنشاء الدرس');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<List<dynamic>> getDisabilityTypes() async {
    try {
      final res = await authGet('/disability-types');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['disability_types'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== دوال التقدم (Progress) =====

  static Future<Map<String, dynamic>?> getChildProgress(
      int childId) async {
    try {
      final res = await authGet('/progress/child/$childId');
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data;
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getChildProgressSummary(
      int childId) async {
    try {
      final res = await authGet('/progress/child/$childId/summary');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['summary'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> markLessonProgress({
    required int childId,
    required int lessonId,
    required String status,
    int? score,
  }) async {
    try {
      final res = await authPost('/progress', {
        'child_id': childId,
        'lesson_id': lessonId,
        'status': status,
        'score': score,
      });

      final data = _decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return data['progress'];
      }
      throw Exception(data['error'] ?? 'فشل تسجيل التقدم');
    } catch (e) {
      _handleError(e);
    }
  }

  // ===== دوال الإشعارات (Notifications) =====

  static Future<List<dynamic>> getNotifications() async {
    try {
      final res = await authGet('/notifications');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['notifications'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<int> getUnreadNotificationsCount() async {
    try {
      final res = await authGet('/notifications/unread/count');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> markNotificationRead(int notificationId) async {
    try {
      await authPut('/notifications/$notificationId/read', {});
    } catch (_) {}
  }

  static Future<void> markAllNotificationsRead() async {
    try {
      await authPost('/notifications/read-all', {});
    } catch (_) {}
  }

  // ===== دوال المحادثات (Conversations) =====

  static Future<List<dynamic>> getConversations() async {
    try {
      final res = await authGet('/conversations');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['conversations'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      final res =
          await authGet('/conversations/$conversationId/messages');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['messages'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> sendMessage({
    required int conversationId,
    required String content,
    String? fileUrl,
  }) async {
    try {
      await authPost('/conversations/$conversationId/messages', {
        'content': content,
        'file_url': fileUrl,
      });
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<int> createConversation(
      int otherUserId, String subject) async {
    try {
      final res = await authPost('/conversations', {
        'other_user_id': otherUserId,
        'subject': subject,
      });

      final data = _decodeBody(res);
      if (res.statusCode == 201) {
        return data['conversation']['id'];
      }
      throw Exception(data['error'] ?? 'فشل إنشاء المحادثة');
    } catch (e) {
      _handleError(e);
    }
  }

  // ===== دوال المستخدمين (Users) =====

  static Future<List<dynamic>> getConversationUsers() async {
    try {
      final res = await authGet('/conversation-users');
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data['users'] ?? [];
      throw Exception(data['error'] ?? 'تعذّر تحميل جهات الاتصال');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<List<dynamic>> getUsers({String? role}) async {
    try {
      String path = '/users';
      if (role != null) {
        path += '?role=$role';
      }
      final res = await authGet(path);
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['users'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getTeachers() async {
    return getUsers(role: 'teacher');
  }

  static Future<List<dynamic>> getSpecialists() async {
    return getUsers(role: 'specialist');
  }

  static Future<List<dynamic>> getParents() async {
    return getUsers(role: 'parent');
  }

  static Future<Map<String, dynamic>?> updateUser(
      int userId, Map<String, dynamic> data) async {
    try {
      final res = await authPut('/users/$userId', data);
      final responseData = _decodeBody(res);
      if (res.statusCode == 200) {
        return responseData['user'];
      }
      throw Exception(responseData['error'] ?? 'فشل تحديث المستخدم');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<bool> deleteUser(int userId) async {
    try {
      final res = await authDelete('/users/$userId');
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== دوال إضافية =====

  static Future<List<dynamic>> searchLessons(String query) async {
    try {
      final res = await authGet(
          '/lessons/search?q=${Uri.encodeComponent(query)}');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== دوال التوثيق (Verification) =====

  static Future<String?> getVerificationStatus() async {
    try {
      final res = await authGet('/me/verification');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        final verification = data['verification'];
        final status = verification is Map
            ? verification['verification_status'] as String?
            : null;
        return status == 'verified' ? 'approved' : (status ?? 'none');
      }
      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  static Future<void> submitIdentityVerification({
    required String nationalId,
    required File idImage,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception(
            'انتهت جلسة تسجيل الدخول، يرجى تسجيل الدخول مجدداً');
      }
      if (!await idImage.exists()) {
        throw Exception('ملف الهوية غير موجود، يرجى اختياره مجدداً');
      }

      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/uploads'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
            await http.MultipartFile.fromPath('file', idImage.path));

      final uploadResponse = await uploadRequest.send();
      final uploadBody = await uploadResponse.stream.bytesToString();
      final uploadData = uploadBody.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(uploadBody) as Map<String, dynamic>);

      if (uploadResponse.statusCode != 200 &&
          uploadResponse.statusCode != 201) {
        throw Exception(uploadData['error'] ?? 'تعذّر رفع صورة الهوية');
      }

      final documentUrl = uploadData['url'] as String?;
      if (documentUrl == null || documentUrl.isEmpty) {
        throw Exception('لم يُرجع السيرفر رابط ملف الهوية');
      }

      final response = await authPost('/me/identity', {
        'national_id': nationalId,
        'id_document_url': documentUrl,
      });
      final data = _decodeBody(response);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data['error'] ?? 'تعذّر إرسال التوثيق');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<bool> isVerified() async {
    final status = await getVerificationStatus();
    return status == 'approved';
  }

  // ===== دوال الأدمن (Admin) =====

  static Future<List<dynamic>> getVerificationRequests() async {
    try {
      final res = await authGet('/admin/verifications');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['requests'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> approveVerification(int requestId) async {
    try {
      final res = await authPost(
          '/admin/verifications/$requestId/approve', {});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rejectVerification(int requestId) async {
    try {
      final res =
          await authPost('/admin/verifications/$requestId/reject', {});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> searchByIdentity(String query) async {
    try {
      final res = await authGet(
          '/admin/search?q=${Uri.encodeComponent(query)}');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== دوال الشهادات والاستشارات =====

  static Future<void> submitCertificate({
    required String title,
    required File file,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('${Config.baseUrl}/certificates');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title;

      if (await file.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = responseBody.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data['error'] ?? 'تعذّر حفظ الشهادة');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<void> requestConsultation({
    required int childId,
    required String title,
    required String description,
  }) async {
    try {
      final res = await authPost('/consultations', {
        'child_id': childId,
        'title': title,
        'description': description,
      });
      final data = _decodeBody(res);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(data['error'] ?? 'تعذّر إرسال الطلب');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // ===== دوال الموافقات الوزارية (Ministry Approvals) =====

  static Future<Map<String, dynamic>?> submitForMinistryApproval({
    required int childId,
    required int evaluationId,
    required String educationalPlan,
    required String cognitiveAssessment,
    required String motorAssessment,
    required String emotionalAssessment,
    required String socialAssessment,
    required String recommendations,
    required List<String> teachingMethods,
    int? teacherId,
  }) async {
    try {
      final res = await authPost('/ministry/approvals', {
        'child_id': childId,
        'evaluation_id': evaluationId,
        'educational_plan': educationalPlan,
        'cognitive_assessment': cognitiveAssessment,
        'motor_assessment': motorAssessment,
        'emotional_assessment': emotionalAssessment,
        'social_assessment': socialAssessment,
        'recommendations': recommendations,
        'teaching_methods': teachingMethods,
        'teacher_id': teacherId,
      });
      final data = _decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return data['approval'];
      }
      throw Exception(data['error'] ?? 'فشل إرسال الطلب');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<List<dynamic>> getPendingApprovals() async {
    try {
      final res = await authGet('/ministry/approvals/pending');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['approvals'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAllApprovals({String? status}) async {
    try {
      final path = status != null
          ? '/ministry/approvals?status=$status'
          : '/ministry/approvals';
      final res = await authGet(path);
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['approvals'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> approveMinistryRequest(int approvalId) async {
    try {
      final res = await authPost(
        '/ministry/approvals/$approvalId/approve',
        {},
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rejectMinistryRequest(
    int approvalId, {
    String? reason,
  }) async {
    try {
      final res = await authPost(
        '/ministry/approvals/$approvalId/reject',
        {'reason': reason ?? ''},
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getApprovalNotifications() async {
    try {
      final res = await authGet('/ministry/approvals/notifications');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['notifications'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String> getChildPlanStatus(int childId) async {
    try {
      final res = await authGet(
          '/ministry/approvals/child/$childId/status');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['status'] ?? 'none';
      }
      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  static Future<List<dynamic>> getMinistryUsers() async {
    try {
      final res = await authGet('/ministry/users');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['users'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMinistryChildren() async {
    try {
      final res = await authGet('/ministry/children');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['children'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMinistryStats() async {
    try {
      final res = await authGet('/ministry/stats');
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data;
      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  الواجبات (Homework)
  // ═══════════════════════════════════════════════════════════
  static Future<List<dynamic>> getHomeworks({int? childId}) async {
    try {
      final path = childId != null
          ? '/homeworks?child_id=$childId'
          : '/homeworks';
      final res = await authGet(path);
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data['homeworks'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createHomework({
    required String title,
    required String description,
    required DateTime dueDate,
    String? subject,
    required List<int> assignedChildIds,
    List<File>? attachments,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/homeworks'),
      )..headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['due_date'] = dueDate.toIso8601String();
      if (subject != null) request.fields['subject'] = subject;
      request.fields['assigned_child_ids'] = jsonEncode(assignedChildIds);

      if (attachments != null) {
        for (final file in attachments) {
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                  'attachments[]', file.path),
            );
          }
        }
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (response.statusCode == 201) return data['homework'];
      throw Exception(data['error'] ?? 'فشل إنشاء الواجب');
    } catch (e) {
      _handleError(e);
    }
  }

  /// ✅ مُصلَّحة: ترسل كل الملفات (file + files)
  static Future<Map<String, dynamic>?> submitHomework({
    required int homeworkId,
    required int childId,
    String? textAnswer,
    File? file,
    List<File>? files,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/homeworks/$homeworkId/submit'),
      )..headers['Authorization'] = 'Bearer $token';

      request.fields['child_id'] = childId.toString();
      if (textAnswer != null && textAnswer.isNotEmpty) {
        request.fields['text_answer'] = textAnswer;
      }

      // ✅ اجمع كل الملفات (المفرد + المتعدد)
      final allFiles = <File>[
        if (file != null) file,
        ...?files,
      ];

      for (final f in allFiles) {
        if (await f.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('files[]', f.path),
          );
        }
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data['submission'] ?? data;
      }
      throw Exception(data['error'] ?? 'فشل تسليم الواجب');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<bool> gradeHomework({
    required int submissionId,
    required int grade,
    String? feedback,
  }) async {
    try {
      final res = await authPut(
          '/homeworks/submissions/$submissionId/grade', {
        'grade': grade,
        'feedback': feedback,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  الدعم التعليمي (legacy Learning Support API identifiers)
  // ═══════════════════════════════════════════════════════════
  static Future<List<dynamic>> getLearningSupportMeetings({int? childId}) async {
    try {
      final path = childId != null
          ? '/learning-support/meetings?child_id=$childId'
          : '/learning-support/meetings';
      final res = await authGet(path);
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data['sessions'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createLearningSupportMeeting({
    required int childId,
    required String type,
    required DateTime scheduledAt,
    int durationMinutes = 45,
    String? goals,
  }) async {
    try {
      final res = await authPost('/learning-support/meetings', {
        'child_id': childId,
        'type': type,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'goals': goals,
      });
      final data = _decodeBody(res);
      if (res.statusCode == 201) return data['session'];
      throw Exception(data['error'] ?? 'فشل إنشاء الجلسة');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<bool> completeLearningSupportMeeting({
    required int sessionId,
    required String notes,
    required String recommendations,
    int? moodRating,
    List<String>? tags,
  }) async {
    try {
      final res = await authPut(
          '/learning-support/meetings/$sessionId/complete', {
        'notes': notes,
        'recommendations': recommendations,
        'mood_rating': moodRating,
        'tags': tags,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  التقارير الأسبوعية (Weekly Reports)
  // ═══════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>?> getWeeklyReport({
    required int childId,
    DateTime? weekStart,
  }) async {
    try {
      final week = weekStart ?? _lastMonday();
      final res = await authGet(
        '/reports/weekly?child_id=$childId&week_start=${week.toIso8601String()}',
      );
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data['report'];
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getChildWeeklyReports(int childId) async {
    try {
      final res = await authGet('/reports/weekly/child/$childId');
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data['reports'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  static DateTime _lastMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  // ═══════════════════════════════════════════════════════════
  //  فريق الرعاية (Care Team)
  // ═══════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>?> getCareTeam(int childId) async {
    try {
      final res = await authGet('/children/$childId/care-team');
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data['care_team'];
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> addCareTeamMember({
    required int childId,
    required int userId,
    required String role,
    String? specialty,
    String? subject,
  }) async {
    try {
      final res = await authPost('/children/$childId/care-team', {
        'user_id': userId,
        'role': role,
        'specialty': specialty,
        'subject': subject,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeCareTeamMember({
    required int childId,
    required int userId,
  }) async {
    try {
      final res = await authDelete(
          '/children/$childId/care-team/$userId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  تقييم الخطة (Plan Evaluation)
  // ═══════════════════════════════════════════════════════════
  static Future<bool> evaluatePlanAppropriateness({
    required int childId,
    required int planId,
    required bool isAppropriate,
    String? notesForTeacher,
    List<String>? recommendedChanges,
  }) async {
    try {
      final res = await authPost('/plans/$planId/evaluate', {
        'child_id': childId,
        'is_plan_appropriate': isAppropriate,
        'notes_for_teacher': notesForTeacher,
        'recommended_changes': recommendedChanges,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  إحصائيات الوزارة (Ministry Statistics)
  // ═══════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>?> getMinistryStatistics() async {
    try {
      final res = await authGet('/ministry/statistics');
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data;
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getMinistryProgressStats() async {
    try {
      final res = await authGet('/ministry/statistics/progress');
      final data = _decodeBody(res);
      if (res.statusCode == 200) return data;
      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  طلبات الدعم التعليمي (Learning Support Requests)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>?> createLearningSupportRequest({
    required int childId,
    required String reason,
    String? description,
    String urgency = 'medium',
  }) async {
    try {
      final res = await authPost('/learning-support/requests', {
        'child_id': childId,
        'reason': reason,
        'description': description,
        'urgency': urgency,
      });
      final data = _decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return data['request'];
      }
      throw Exception(data['error'] ?? 'فشل إرسال الطلب');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<List<dynamic>> getLearningSupportRequests({
    int? childId,
    String? status,
  }) async {
    try {
      final params = <String>[];
      if (childId != null) params.add('child_id=$childId');
      if (status != null) params.add('status=$status');
      final path = params.isEmpty
          ? '/learning-support/requests'
          : '/learning-support/requests?${params.join('&')}';

      final res = await authGet(path);
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['requests'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> hasPendingLearningSupportRequest(int childId) async {
    try {
      final res =
          await authGet('/learning-support/requests/child/$childId/pending');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['has_pending'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> scheduleLearningSupportRequest({
    required int requestId,
    required DateTime scheduledAt,
    required String meetingLink,
    String? notes,
  }) async {
    try {
      final res = await authPut('/learning-support/requests/$requestId/schedule', {
        'scheduled_at': scheduledAt.toIso8601String(),
        'meeting_link': meetingLink,
        'specialist_notes': notes,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> cancelLearningSupportRequest(int requestId) async {
    try {
      final res =
          await authPut('/learning-support/requests/$requestId/cancel', {});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  الملف الشخصي (Profile)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await authGet('/me');
      final data = _decodeBody(res);
      if (res.statusCode == 200) {
        return data['user'] ?? data;
      }
      throw Exception(data['error'] ?? 'تعذّر تحميل الملف الشخصي');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await authPut('/me/password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      final data = _decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 204) {
        return;
      }
      throw Exception(data['error'] ?? 'فشل تغيير كلمة المرور');
    } catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  صورة البروفايل (Profile Picture)
  // ═══════════════════════════════════════════════════════════

  static Future<String?> uploadProfilePicture(File image) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('انتهت جلسة تسجيل الدخول');
      }
      if (!await image.exists()) {
        throw Exception('ملف الصورة غير موجود');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/me/avatar'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath('avatar', image.path),
        );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final url = data['avatar_url'] as String?;
        if (url != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('avatar_url', url);
        }
        return url;
      }
      throw Exception(data['error'] ?? 'فشل رفع الصورة');
    } catch (e) {
      _handleError(e);
    }
  }

  static Future<bool> removeProfilePicture() async {
    try {
      final res = await authDelete('/me/avatar');
      if (res.statusCode == 200 || res.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('avatar_url');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getSavedAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('avatar_url');
  }

  static Future<void> saveAvatarUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove('avatar_url');
    } else {
      await prefs.setString('avatar_url', url);
    }
  }
 

// ═══════════════════════════════════════════════════════════
//  تعيين متعدد
// ═══════════════════════════════════════════════════════════

/// المختص يعيّن معلماً إضافياً لطفل (يسمح بأكثر من معلم)
static Future<bool> addTeacherToChild({
  required int childId,
  required int teacherId,
}) async {
  try {
    final res = await authPost('/children/$childId/teachers', {
      'teacher_id': teacherId,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  } catch (e) {
    return false;
  }
}

static Future<bool> removeTeacherFromChild({
  required int childId,
  required int teacherId,
}) async {
  try {
    final res = await authDelete('/children/$childId/teachers/$teacherId');
    return res.statusCode == 200 || res.statusCode == 204;
  } catch (e) {
    return false;
  }
}

static Future<List<dynamic>> getChildTeachers(int childId) async {
  try {
    final res = await authGet('/children/$childId/teachers');
    final data = _decodeBody(res);
    if (res.statusCode == 200) return data['teachers'] ?? [];
    return [];
  } catch (e) {
    return [];
  }
}

// ═══════════════════════════════════════════════════════════
//  تعيين مختصي الدعم التعليمي
// ═══════════════════════════════════════════════════════════

static Future<Map<String, dynamic>?> getChildSpecialists(int childId) async {
  try {
    final res = await authGet('/children/$childId/specialists');
    final data = _decodeBody(res);
    if (res.statusCode == 200) return data;
    return null;
  } catch (e) {
    return null;
  }
}

static Future<String?> assignSpecialist({
  required int childId,
  required int specialistId,
  required String specialty, // learning_support | educational | communication_support | learning_behavior
}) async {
  try {
    final res = await authPost('/children/$childId/specialists', {
      'specialist_id': specialistId,
      'specialty': specialty,
    });
    final data = _decodeBody(res);
    if (res.statusCode == 200 || res.statusCode == 201) return null;
    return data['error'] ?? 'فشل التعيين';
  } catch (e) {
    return 'تعذّر الاتصال بالسيرفر';
  }
}

static Future<bool> removeSpecialist({
  required int childId,
  required int specialistId,
}) async {
  try {
    final res =
        await authDelete('/children/$childId/specialists/$specialistId');
    return res.statusCode == 200 || res.statusCode == 204;
  } catch (e) {
    return false;
  }
}


// ═══════════════════════════════════════════════════════════
//  دراسات الحالة
// ═══════════════════════════════════════════════════════════

static Future<List<dynamic>> getCaseDiscussions({int? childId}) async {
  try {
    final path = childId != null
        ? '/case-discussions?child_id=$childId'
        : '/case-discussions';
    final res = await authGet(path);
    final data = _decodeBody(res);
    if (res.statusCode == 200) return data['discussions'] ?? [];
    return [];
  } catch (_) {
    return [];
  }
}

static Future<Map<String, dynamic>?> createCaseDiscussion({
  required int childId,
  required String topic,
  String? description,
  required List<int> participantIds,
}) async {
  try {
    final res = await authPost('/case-discussions', {
      'child_id': childId,
      'topic': topic,
      'description': description,
      'participant_ids': participantIds,
    });
    final data = _decodeBody(res);
    if (res.statusCode == 201) return data['discussion'];
    throw Exception(data['error'] ?? 'فشل إنشاء الدراسة');
  } catch (e) {
    _handleError(e);
  }
}

static Future<Map<String, dynamic>?> getCaseDiscussionDetails(
    int discussionId) async {
  try {
    final res = await authGet('/case-discussions/$discussionId');
    final data = _decodeBody(res);
    if (res.statusCode == 200) return data['discussion'];
    return null;
  } catch (_) {
    return null;
  }
}

static Future<Map<String, dynamic>?> addCaseMessage({
  required int discussionId,
  required String content,
  String type = 'text',
}) async {
  try {
    final res = await authPost('/case-discussions/$discussionId/messages', {
      'content': content,
      'type': type,
    });
    final data = _decodeBody(res);
    if (res.statusCode == 201) return data['message'];
    throw Exception(data['error'] ?? 'فشل إرسال الرسالة');
  } catch (e) {
    _handleError(e);
  }
}

static Future<bool> resolveCaseDiscussion(int discussionId) async {
  try {
    final res = await authPut('/case-discussions/$discussionId/resolve', {});
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}
// ═══════════════════════════════════════════════════════════
//  اقتراحات المختصين
// ═══════════════════════════════════════════════════════════

/// اقتراح مختص لطفل (يُرسل إشعار للمختص المقترح)
static Future<String?> suggestSpecialistToChild({
  required int childId,
  required int specialistId,
  required String specialty,
  required String reason,
}) async {
  try {
    final res = await authPost(
      '/children/$childId/specialist-suggestions',
      {
        'specialist_id': specialistId,
        'specialty': specialty,
        'reason': reason,
      },
    );
    if (res.statusCode == 200 || res.statusCode == 201) return null;
    final data = _decodeBody(res);
    return data['error'] ?? 'فشل إرسال التوصية';
  } catch (e) {
    return 'تعذّر الاتصال بالسيرفر';
  }
}

/// اقتراحاتي (التي وصلتني كمختص)
static Future<List<dynamic>> getMySpecialistSuggestions({
  String? status,
}) async {
  try {
    final path = status != null
        ? '/specialist-suggestions?status=$status'
        : '/specialist-suggestions';
    final res = await authGet(path);
    final data = _decodeBody(res);
    if (res.statusCode == 200) return data['suggestions'] ?? [];
    return [];
  } catch (_) {
    return [];
  }
}

/// قبول اقتراح
static Future<String?> acceptSuggestion(int suggestionId) async {
  try {
    final res = await authPut(
      '/specialist-suggestions/$suggestionId/accept', {},
    );
    if (res.statusCode == 200) return null;
    final data = _decodeBody(res);
    return data['error'] ?? 'فشل القبول';
  } catch (e) {
    return 'تعذّر الاتصال بالسيرفر';
  }
}

/// رفض اقتراح
static Future<String?> rejectSuggestion(
  int suggestionId, {
  String? reason,
}) async {
  try {
    final res = await authPut(
      '/specialist-suggestions/$suggestionId/reject',
      {'reason': reason ?? ''},
    );
    if (res.statusCode == 200) return null;
    final data = _decodeBody(res);
    return data['error'] ?? 'فشل الرفض';
  } catch (e) {
    return 'تعذّر الاتصال بالسيرفر';
  }
}
  // ===== حذف الحساب =====
  static Future<void> deleteAccount() async {
    try {
      final res = await authDelete('/me');
      final data = _decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 204) {
        await logout();
        return;
      }
      throw Exception(data['error'] ?? 'تعذّر حذف الحساب');
    } on SocketException {
      throw Exception('تعذّر الاتصال بالسيرفر');
    } on http.ClientException {
      throw Exception('تعذّر الاتصال بالسيرفر');
    } on FormatException {
      throw Exception('استجابة السيرفر غير صالحة، حاول مرة أخرى');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('تعذّر حذف الحساب');
    }
  }
}