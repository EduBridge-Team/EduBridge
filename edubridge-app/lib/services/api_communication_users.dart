// API implementations for notifications, conversations, users, verification, and certificates.
part of 'api_service.dart';

Future<List<dynamic>> _apiGetNotifications() async {
    try {
      final res = await ApiService.authGet('/notifications');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['notifications'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<int> _apiGetUnreadNotificationsCount() async {
    try {
      final res = await ApiService.authGet('/notifications/unread/count');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

Future<void> _apiMarkNotificationRead(int notificationId) async {
    try {
      await ApiService.authPut('/notifications/$notificationId/read', {});
    } catch (_) {}
  }

Future<void> _apiMarkAllNotificationsRead() async {
    try {
      await ApiService.authPost('/notifications/read-all', {});
    } catch (_) {}
  }

Future<List<dynamic>> _apiGetConversations() async {
    try {
      final res = await ApiService.authGet('/conversations');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['conversations'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<List<dynamic>> _apiGetMessages(int conversationId) async {
    try {
      final res =
          await ApiService.authGet('/conversations/$conversationId/messages');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['messages'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<void> _apiSendMessage({
    required int conversationId,
    required String content,
    String? fileUrl,
  }) async {
    try {
      await ApiService.authPost('/conversations/$conversationId/messages', {
        'content': content,
        'file_url': fileUrl,
      });
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<int> _apiCreateConversation(
      int otherUserId, String subject) async {
    try {
      final res = await ApiService.authPost('/conversations', {
        'other_user_id': otherUserId,
        'subject': subject,
      });

      final data = ApiService._decodeBody(res);
      if (res.statusCode == 201) {
        final conv = ApiService._asStringMap(data['conversation']);
        return conv?['id'] ?? 0;
      }
      throw Exception(data['error'] ?? 'فشل إنشاء المحادثة');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _apiGetConversationUsers() async {
    try {
      final res = await ApiService.authGet('/conversation-users');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data['users'] ?? [];
      throw Exception(data['error'] ?? 'تعذّر تحميل جهات الاتصال');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _apiGetUsers({String? role}) async {
    try {
      String path = '/users';
      if (role != null) {
        path += '?role=$role';
      }
      final res = await ApiService.authGet(path);
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['users'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<List<dynamic>> _apiGetTeachers() async {
    return _apiGetUsers(role: 'teacher');
  }

Future<List<dynamic>> _apiGetSpecialists() async {
    return _apiGetUsers(role: 'specialist');
  }

Future<List<dynamic>> _apiGetParents() async {
    return _apiGetUsers(role: 'parent');
  }

Future<Map<String, dynamic>?> _apiUpdateUser(
      int userId, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.authPut('/users/$userId', data);
      final responseData = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return ApiService._asStringMap(responseData['user']);
      }
      throw Exception(responseData['error'] ?? 'فشل تحديث المستخدم');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<bool> _apiDeleteUser(int userId) async {
    try {
      final res = await ApiService.authDelete('/users/$userId');
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<Map<String, dynamic>?> _apiGetDashboardStats() async {
    try {
      final res = await ApiService.authGet('/dashboard/stats');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data;
      return null;
    } catch (e) {
      return null;
    }
  }

Future<List<dynamic>> _apiSearchLessons(String query) async {
    try {
      final res = await ApiService.authGet(
          '/lessons/search?q=${Uri.encodeComponent(query)}');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['lessons'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<String?> _apiGetVerificationStatus() async {
    try {
      final res = await ApiService.authGet('/me/verification');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        final verification = ApiService._asStringMap(data['verification']);
        final status = verification?['verification_status'] as String?;
        return status == 'verified' ? 'approved' : (status ?? 'none');
      }
      return 'none';
    } catch (e) {
      return 'none';
    }
  }

Future<void> _apiSubmitIdentityVerification({
    required String nationalId,
    required File idImage,
  }) async {
    try {
      final token = await ApiService.getToken();
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
      final uploadData = ApiService.decodeMap(uploadBody);

      if (uploadResponse.statusCode != 200 &&
          uploadResponse.statusCode != 201) {
        throw Exception(uploadData['error'] ?? 'تعذّر رفع صورة الهوية');
      }

      final documentUrl = uploadData['url'] as String?;
      if (documentUrl == null || documentUrl.isEmpty) {
        throw Exception('لم يُرجع السيرفر رابط ملف الهوية');
      }

      final response = await ApiService.authPost('/me/identity', {
        'national_id': nationalId,
        'id_document_url': documentUrl,
      });
      final data = ApiService._decodeBody(response);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data['error'] ?? 'تعذّر إرسال التوثيق');
      }
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<bool> _apiIsVerified() async {
    final status = await _apiGetVerificationStatus();
    return status == 'approved';
  }

Future<List<dynamic>> _apiGetVerificationRequests() async {
    try {
      final res = await ApiService.authGet('/admin/verifications');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['requests'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<bool> _apiApproveVerification(int requestId) async {
    try {
      final res = await ApiService.authPost(
          '/admin/verifications/$requestId/approve', {});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<bool> _apiRejectVerification(int requestId) async {
    try {
      final res =
          await ApiService.authPost('/admin/verifications/$requestId/reject', {});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<List<dynamic>> _apiSearchByIdentity(String query) async {
    try {
      final res = await ApiService.authGet(
          '/admin/search?q=${Uri.encodeComponent(query)}');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['results'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<void> _apiSubmitCertificate({
    required String title,
    required File file,
  }) async {
    try {
      final token = await ApiService.getToken();
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
      final data = ApiService.decodeMap(responseBody);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data['error'] ?? 'تعذّر حفظ الشهادة');
      }
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<void> _apiRequestConsultation({
    required int childId,
    required String title,
    required String description,
  }) async {
    try {
      final res = await ApiService.authPost('/consultations', {
        'child_id': childId,
        'title': title,
        'description': description,
      });
      final data = ApiService._decodeBody(res);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(data['error'] ?? 'تعذّر إرسال الطلب');
      }
    } catch (e) {
      ApiService._handleError(e);
    }
  }
