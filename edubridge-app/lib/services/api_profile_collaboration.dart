// API implementations for profile, collaboration, case discussions, suggestions, and account.
part of 'api_service.dart';

Future<Map<String, dynamic>?> _apiGetProfile() async {
    try {
      final res = await ApiService.authGet('/me');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return ApiService._asStringMap(data['user'] ?? data);
      }
      throw Exception(data['error'] ?? 'تعذّر تحميل الملف الشخصي');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<void> _apiChangePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await ApiService.authPut('/me/password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 204) {
        return;
      }
      throw Exception(data['error'] ?? 'فشل تغيير كلمة المرور');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<String?> _apiUploadProfilePicture(File image) async {
    try {
      final token = await ApiService.getToken();
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
      final data = ApiService.decodeMap(body);

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
      ApiService._handleError(e);
    }
  }

Future<bool> _apiRemoveProfilePicture() async {
    try {
      final res = await ApiService.authDelete('/me/avatar');
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

Future<String?> _apiGetSavedAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('avatar_url');
  }

Future<void> _apiSaveAvatarUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove('avatar_url');
    } else {
      await prefs.setString('avatar_url', url);
    }
  }

Future<bool> _apiAddTeacherToChild({
    required int childId,
    required int teacherId,
  }) async {
    try {
      final res = await ApiService.authPost('/children/$childId/teachers', {
        'teacher_id': teacherId,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

Future<bool> _apiRemoveTeacherFromChild({
    required int childId,
    required int teacherId,
  }) async {
    try {
      final res = await ApiService.authDelete('/children/$childId/teachers/$teacherId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

Future<List<dynamic>> _apiGetChildTeachers(int childId) async {
    try {
      final res = await ApiService.authGet('/children/$childId/teachers');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data['teachers'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiGetChildSpecialists(
      int childId) async {
    try {
      final res = await ApiService.authGet('/children/$childId/specialists');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return ApiService._asStringMap(data);
      return null;
    } catch (e) {
      return null;
    }
  }

Future<String?> _apiAssignSpecialist({
    required int childId,
    required int specialistId,
    required String specialty,
  }) async {
    try {
      final res = await ApiService.authPost('/children/$childId/specialists', {
        'specialist_id': specialistId,
        'specialty': specialty,
      });
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return data['error'] ?? 'فشل التعيين';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

Future<bool> _apiRemoveSpecialist({
    required int childId,
    required int specialistId,
  }) async {
    try {
      final res =
          await ApiService.authDelete('/children/$childId/specialists/$specialistId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

Future<List<dynamic>> _apiGetCaseDiscussions({int? childId}) async {
    try {
      final path = childId != null
          ? '/case-discussions?child_id=$childId'
          : '/case-discussions';
      final res = await ApiService.authGet(path);
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data['discussions'] ?? [];
      return [];
    } catch (_) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiCreateCaseDiscussion({
    required int childId,
    required String topic,
    String? description,
    required List<int> participantIds,
  }) async {
    try {
      final res = await ApiService.authPost('/case-discussions', {
        'child_id': childId,
        'topic': topic,
        'description': description,
        'participant_ids': participantIds,
      });
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 201) {
        return ApiService._asStringMap(data['discussion']);
      }
      throw Exception(data['error'] ?? 'فشل إنشاء الدراسة');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<Map<String, dynamic>?> _apiGetCaseDiscussionDetails(
      int discussionId) async {
    try {
      final res = await ApiService.authGet('/case-discussions/$discussionId');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return ApiService._asStringMap(data['discussion']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

Future<Map<String, dynamic>?> _apiAddCaseMessage({
    required int discussionId,
    required String content,
    String type = 'text',
  }) async {
    try {
      final res =
          await ApiService.authPost('/case-discussions/$discussionId/messages', {
        'content': content,
        'type': type,
      });
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 201) {
        return ApiService._asStringMap(data['message']);
      }
      throw Exception(data['error'] ?? 'فشل إرسال الرسالة');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<bool> _apiResolveCaseDiscussion(int discussionId) async {
    try {
      final res =
          await ApiService.authPut('/case-discussions/$discussionId/resolve', {});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

Future<String?> _apiSuggestSpecialistToChild({
    required int childId,
    required int specialistId,
    required String specialty,
    required String reason,
  }) async {
    try {
      final res = await ApiService.authPost(
        '/children/$childId/specialist-suggestions',
        {
          'specialist_id': specialistId,
          'specialty': specialty,
          'reason': reason,
        },
      );
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      final data = ApiService._decodeBody(res);
      return data['error'] ?? 'فشل إرسال التوصية';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

Future<List<dynamic>> _apiGetMySpecialistSuggestions({
    String? status,
  }) async {
    try {
      final path = status != null
          ? '/specialist-suggestions?status=$status'
          : '/specialist-suggestions';
      final res = await ApiService.authGet(path);
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data['suggestions'] ?? [];
      return [];
    } catch (_) {
      return [];
    }
  }

Future<String?> _apiAcceptSuggestion(int suggestionId) async {
    try {
      final res = await ApiService.authPut(
        '/specialist-suggestions/$suggestionId/accept', {},
      );
      if (res.statusCode == 200) return null;
      final data = ApiService._decodeBody(res);
      return data['error'] ?? 'فشل القبول';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

Future<String?> _apiRejectSuggestion(
    int suggestionId, {
    String? reason,
  }) async {
    try {
      final res = await ApiService.authPut(
        '/specialist-suggestions/$suggestionId/reject',
        {'reason': reason ?? ''},
      );
      if (res.statusCode == 200) return null;
      final data = ApiService._decodeBody(res);
      return data['error'] ?? 'فشل الرفض';
    } catch (e) {
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

Future<void> _apiDeleteAccount() async {
    try {
      final res = await ApiService.authDelete('/me');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 204) {
        await ApiService.logout();
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
