// طبقة الاتصال بالـ API - كاملة ومتكاملة
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  // ===== دوال التخزين المحلي =====
  
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('userId');
  }

  // ===== دوال المصادقة (Auth) =====
  
  static Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200) {
        await _saveToken(data['token']);
        if (data['user'] != null) {
          await saveUserData(data['user']);
        }
        return null; // نجاح
      }
      return data['error'] ?? 'فشل تسجيل الدخول';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

  static Future<String?> register(
    String name,
    String email,
    String password,
    String role,
    {String? phone}
  ) async {
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
        }),
      );

      final data = jsonDecode(res.body);
      
      if (res.statusCode == 201) {
        return null; // نجاح
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

  static Future<http.Response> authPost(String path, Map<String, dynamic> body) async {
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

  static Future<http.Response> authPut(String path, Map<String, dynamic> body) async {
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
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data;
      }
      throw Exception(data['error'] ?? 'فشل جلب الأطفال');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  static Future<Map<String, dynamic>?> addChild({
    required String name,
    required int age,
    String? disabilityType,
    String? disabilityDescription,
    String? medicalHistory,
    String? psychologistNotes,
    String? specialNeeds,
    String? preferredLearningStyle,
    List<String>? strengths,
    List<String>? challenges,
  }) async {
    try {
      final res = await authPost('/children', {
        'name': name,
        'age': age,
        'disability_type': disabilityType,
        'disability_description': disabilityDescription,
        'medical_history': medicalHistory,
        'psychologist_notes': psychologistNotes,
        'special_needs': specialNeeds,
        'preferred_learning_style': preferredLearningStyle,
        'strengths': strengths,
        'challenges': challenges,
      });
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return data['child'];
      }
      throw Exception(data['error'] ?? 'فشل إضافة الطفل');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  static Future<Map<String, dynamic>?> getChildDetails(int childId) async {
    try {
      final res = await authGet('/children/$childId');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['child'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateChild(
    int childId,
    Map<String, dynamic> data
  ) async {
    try {
      final res = await authPut('/children/$childId', data);
      final responseData = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return responseData['child'];
      }
      throw Exception(responseData['error'] ?? 'فشل تحديث بيانات الطفل');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  static Future<List<dynamic>> getChildLessons(int childId) async {
    try {
      final res = await authGet('/children/$childId/lessons');
      final data = jsonDecode(res.body);
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
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return data['evaluation'];
      }
      throw Exception(data['error'] ?? 'فشل تقييم الطفل');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  static Future<List<dynamic>> getChildEvaluations(int childId) async {
    try {
      final res = await authGet('/evaluations/child/$childId');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['evaluations'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> assignTeacherToChild(
    int childId,
    int teacherId
  ) async {
    try {
      final res = await authPost('/children/$childId/assign-teacher', {
        'teacher_id': teacherId,
      });
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['child'];
      }
      throw Exception(data['error'] ?? 'فشل تعيين المعلم');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  // ===== دوال الدروس (Lessons) =====
  
  static Future<List<dynamic>> getLessons() async {
    try {
      final res = await authGet('/lessons');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLessonDetails(int lessonId) async {
    try {
      final res = await authGet('/lessons/$lessonId');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['lesson'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createLessonWithMedia({
    required String title,
    String? content,
    int? disabilityTypeId,
    File? videoFile,
    File? audioFile,
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
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      
      if (response.statusCode == 201) {
        return data['lesson'];
      }
      throw Exception(data['error'] ?? 'فشل إنشاء الدرس');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  static Future<List<dynamic>> getDisabilityTypes() async {
    try {
      final res = await authGet('/disability-types');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['disability_types'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== دوال التقدم (Progress) =====
  
  static Future<Map<String, dynamic>?> getChildProgress(int childId) async {
    try {
      final res = await authGet('/progress/child/$childId');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getChildProgressSummary(int childId) async {
    try {
      final res = await authGet('/progress/child/$childId/summary');
      final data = jsonDecode(res.body);
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
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return data['progress'];
      }
      throw Exception(data['error'] ?? 'فشل تسجيل التقدم');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  // ===== دوال الإشعارات (Notifications) =====
  
  static Future<List<dynamic>> getNotifications() async {
    try {
      final res = await authGet('/notifications');
      final data = jsonDecode(res.body);
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
      final data = jsonDecode(res.body);
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
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  static Future<void> markAllNotificationsRead() async {
    try {
      await authPost('/notifications/read-all', {});
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  // ===== دوال المحادثات (Conversations) =====
  
  static Future<List<dynamic>> getConversations() async {
    try {
      final res = await authGet('/conversations');
      final data = jsonDecode(res.body);
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
      final res = await authGet('/conversations/$conversationId/messages');
      final data = jsonDecode(res.body);
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
      throw Exception('تعذّر إرسال الرسالة');
    }
  }

  static Future<int> createConversation(int otherUserId, String subject) async {
    try {
      final res = await authPost('/conversations', {
        'other_user_id': otherUserId,
        'subject': subject,
      });
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return data['conversation']['id'];
      }
      throw Exception(data['error'] ?? 'فشل إنشاء المحادثة');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }

  // ===== دوال المستخدمين (Users) =====
  
  static Future<List<dynamic>> getUsers({String? role}) async {
    try {
      String path = '/users';
      if (role != null) {
        path += '?role=$role';
      }
      final res = await authGet(path);
      final data = jsonDecode(res.body);
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
    int userId,
    Map<String, dynamic> data
  ) async {
    try {
      final res = await authPut('/users/$userId', data);
      final responseData = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return responseData['user'];
      }
      throw Exception(responseData['error'] ?? 'فشل تحديث المستخدم');
    } catch (e) {
      throw Exception('تعذّر الاتصال بالسيرفر');
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
  
  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final res = await authGet('/dashboard/stats');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> searchLessons(String query) async {
    try {
      final res = await authGet('/lessons/search?q=${Uri.encodeComponent(query)}');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}