// API implementations for homework, learning support, reports, care team, and requests.
part of 'api_service.dart';

Future<List<dynamic>> _apiGetHomeworks({int? childId}) async {
    try {
      final path = childId != null
          ? '/homeworks?child_id=$childId'
          : '/homeworks';
      final res = await ApiService.authGet(path);
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data['homeworks'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiCreateHomework({
    required String title,
    required String description,
    required DateTime dueDate,
    String? subject,
    required List<int> assignedChildIds,
    List<File>? attachments,
  }) async {
    try {
      final token = await ApiService.getToken();
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
      final data = ApiService.decodeMap(body);

      if (response.statusCode == 201) return ApiService._asStringMap(data['homework']);
      throw Exception(data['error'] ?? 'فشل إنشاء الواجب');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<Map<String, dynamic>?> _apiSubmitHomework({
    required int homeworkId,
    required int childId,
    String? textAnswer,
    File? file,
    List<File>? files,
  }) async {
    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/homeworks/$homeworkId/submit'),
      )..headers['Authorization'] = 'Bearer $token';

      request.fields['child_id'] = childId.toString();
      if (textAnswer != null && textAnswer.isNotEmpty) {
        request.fields['text_answer'] = textAnswer;
      }

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
      final data = ApiService.decodeMap(body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiService._asStringMap(data['submission'] ?? data);
      }
      throw Exception(data['error'] ?? 'فشل تسليم الواجب');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<bool> _apiGradeHomework({
    required int submissionId,
    required int grade,
    String? feedback,
  }) async {
    try {
      final res = await ApiService.authPut(
          '/homeworks/submissions/$submissionId/grade', {
        'grade': grade,
        'feedback': feedback,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<List<dynamic>> _apiGetLearningSupportMeetings({int? childId}) async {
    try {
      final path = childId != null
          ? '/learning-support/meetings?child_id=$childId'
          : '/learning-support/meetings';
      final res = await ApiService.authGet(path);
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data['sessions'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiCreateLearningSupportMeeting({
    required int childId,
    required String type,
    required DateTime scheduledAt,
    int durationMinutes = 45,
    String? goals,
  }) async {
    try {
      final res = await ApiService.authPost('/learning-support/meetings', {
        'child_id': childId,
        'type': type,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'goals': goals,
      });
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 201) return ApiService._asStringMap(data['session']);
      throw Exception(data['error'] ?? 'فشل إنشاء الجلسة');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<bool> _apiCompleteLearningSupportMeeting({
    required int sessionId,
    required String notes,
    required String recommendations,
    int? moodRating,
    List<String>? tags,
  }) async {
    try {
      final res = await ApiService.authPut(
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

Future<Map<String, dynamic>?> _apiGetWeeklyReport({
    required int childId,
    DateTime? weekStart,
  }) async {
    try {
      final week = weekStart ?? _apiLastMonday();
      final res = await ApiService.authGet(
        '/reports/weekly?child_id=$childId&week_start=${week.toIso8601String()}',
      );
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return ApiService._asStringMap(data['report']);
      return null;
    } catch (e) {
      return null;
    }
  }

Future<List<dynamic>> _apiGetChildWeeklyReports(int childId) async {
    try {
      final res = await ApiService.authGet('/reports/weekly/child/$childId');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return data['reports'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _apiGetCareTeam(int childId) async {
    try {
      final res = await ApiService.authGet('/children/$childId/care-team');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return ApiService._asStringMap(data['care_team']);
      return null;
    } catch (e) {
      return null;
    }
  }

Future<bool> _apiAddCareTeamMember({
    required int childId,
    required int userId,
    required String role,
    String? specialty,
    String? subject,
  }) async {
    try {
      final res = await ApiService.authPost('/children/$childId/care-team', {
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

Future<bool> _apiRemoveCareTeamMember({
    required int childId,
    required int userId,
  }) async {
    try {
      final res = await ApiService.authDelete(
          '/children/$childId/care-team/$userId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

Future<bool> _apiEvaluatePlanAppropriateness({
    required int childId,
    required int planId,
    required bool isAppropriate,
    String? notesForTeacher,
    List<String>? recommendedChanges,
  }) async {
    try {
      final res = await ApiService.authPost('/plans/$planId/evaluate', {
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

Future<Map<String, dynamic>?> _apiGetMinistryStatistics() async {
    try {
      final res = await ApiService.authGet('/ministry/statistics');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return ApiService._asStringMap(data);
      return null;
    } catch (e) {
      return null;
    }
  }

Future<Map<String, dynamic>?> _apiGetMinistryProgressStats() async {
    try {
      final res = await ApiService.authGet('/ministry/statistics/progress');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return ApiService._asStringMap(data);
      return null;
    } catch (e) {
      return null;
    }
  }

Future<Map<String, dynamic>?> _apiCreateLearningSupportRequest({
    required int childId,
    required String reason,
    String? description,
    String urgency = 'medium',
  }) async {
    try {
      final res = await ApiService.authPost('/learning-support/requests', {
        'child_id': childId,
        'reason': reason,
        'description': description,
        'urgency': urgency,
      });
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiService._asStringMap(data['request']);
      }
      throw Exception(data['error'] ?? 'فشل إرسال الطلب');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _apiGetLearningSupportRequests({
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

      final res = await ApiService.authGet(path);
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['requests'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<bool> _apiHasPendingLearningSupportRequest(int childId) async {
    try {
      final res =
          await ApiService.authGet('/learning-support/requests/child/$childId/pending');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['has_pending'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

Future<bool> _apiScheduleLearningSupportRequest({
    required int requestId,
    required DateTime scheduledAt,
    required String meetingLink,
    String? notes,
  }) async {
    try {
      final res = await ApiService.authPut('/learning-support/requests/$requestId/schedule', {
        'scheduled_at': scheduledAt.toIso8601String(),
        'meeting_link': meetingLink,
        'specialist_notes': notes,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<bool> _apiCancelLearningSupportRequest(int requestId) async {
    try {
      final res =
          await ApiService.authPut('/learning-support/requests/$requestId/cancel', {});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

DateTime _apiLastMonday() {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1));
}
