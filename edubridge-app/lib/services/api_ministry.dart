// API implementations for ministry approvals and ministry views.
part of 'api_service.dart';

Future<Map<String, dynamic>?> _api_submitForMinistryApproval({
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
      final res = await ApiService.authPost('/ministry/approvals', {
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
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiService._asStringMap(data['approval']);
      }
      throw Exception(data['error'] ?? 'فشل إرسال الطلب');
    } catch (e) {
      ApiService._handleError(e);
    }
  }

Future<List<dynamic>> _api_getPendingApprovals() async {
    try {
      final res = await ApiService.authGet('/ministry/approvals/pending');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['approvals'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<List<dynamic>> _api_getAllApprovals({String? status}) async {
    try {
      final path = status != null
          ? '/ministry/approvals?status=$status'
          : '/ministry/approvals';
      final res = await ApiService.authGet(path);
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['approvals'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<bool> _api_approveMinistryRequest(int approvalId) async {
    try {
      final res = await ApiService.authPost(
        '/ministry/approvals/$approvalId/approve',
        {},
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<bool> _api_rejectMinistryRequest(
    int approvalId, {
    String? reason,
  }) async {
    try {
      final res = await ApiService.authPost(
        '/ministry/approvals/$approvalId/reject',
        {'reason': reason ?? ''},
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<List<dynamic>> _api_getApprovalNotifications() async {
    try {
      final res = await ApiService.authGet('/ministry/approvals/notifications');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['notifications'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<String> _api_getChildPlanStatus(int childId) async {
    try {
      final res = await ApiService.authGet(
          '/ministry/approvals/child/$childId/status');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['status'] ?? 'none';
      }
      return 'none';
    } catch (e) {
      return 'none';
    }
  }

Future<List<dynamic>> _api_getMinistryUsers() async {
    try {
      final res = await ApiService.authGet('/ministry/users');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['users'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<List<dynamic>> _api_getMinistryChildren() async {
    try {
      final res = await ApiService.authGet('/ministry/children');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) {
        return data['children'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

Future<Map<String, dynamic>?> _api_getMinistryStats() async {
    try {
      final res = await ApiService.authGet('/ministry/stats');
      final data = ApiService._decodeBody(res);
      if (res.statusCode == 200) return ApiService._asStringMap(data);
      return null;
    } catch (e) {
      return null;
    }
  }
