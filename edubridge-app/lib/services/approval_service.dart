import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// خدمة إدارة موافقات الوزارة على تقييمات المختص
class ApprovalService {
  static const _pendingKey = 'pending_ministry_approvals';
  static const _approvedKey = 'approved_plans';
  static const _rejectedKey = 'rejected_plans';
  static const _notificationsKey = 'approval_notifications';

  // ===== المختص يرسل تقييماً جديداً =====
  static Future<void> submitForApproval({
    required int childId,
    required String childName,
    required int evaluationId,
    required Map<String, dynamic> evaluationData,
    required int? teacherId,
    required String teacherName,
    required String educationalPlan,
    required String cognitiveAssessment,
    required String motorAssessment,
    required String emotionalAssessment,
    required String socialAssessment,
    required String recommendations,
    required List<String> teachingMethods,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. حفظ في قائمة الانتظار
    final pending = await getPendingApprovals();
    final approval = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'child_id': childId,
      'child_name': childName,
      'evaluation_id': evaluationId,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'educational_plan': educationalPlan,
      'cognitive_assessment': cognitiveAssessment,
      'motor_assessment': motorAssessment,
      'emotional_assessment': emotionalAssessment,
      'social_assessment': socialAssessment,
      'recommendations': recommendations,
      'teaching_methods': teachingMethods,
      'status': 'pending',
      'submitted_at': DateTime.now().toIso8601String(),
    };
    pending.add(approval);
    await prefs.setString(_pendingKey, jsonEncode(pending));

    // 2. إشعار المختص بأن الطلب تم إرساله
    await _addNotification(
      forRole: 'specialist',
      title: 'تم إرسال التقييم للوزارة',
      body: 'تقييم الطفل $childName قيد مراجعة الوزارة',
      type: 'plan_submitted',
    );

    // 3. محاولة إرسال للـ Backend (Best-effort)
    try {
      await ApiService.authPost('/ministry/approvals', {
        'child_id': childId,
        'evaluation_id': evaluationId,
        'educational_plan': educationalPlan,
      });
    } catch (_) {
      // نتجاهل الخطأ إذا لم يكن الـ Backend مدعوماً
    }
  }

  // ===== جلب كل الطلبات المعلّقة (للوزارة) =====
  static Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ===== الوزارة توافق على طلب =====
  static Future<void> approve({
    required String approvalId,
    required String specialistName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await getPendingApprovals();

    final index = pending.indexWhere((p) => p['id'] == approvalId);
    if (index == -1) return;

    final approval = pending.removeAt(index);

    // 1. إضافة للقائمة المعتمدة (المعلم سيراها)
    final approved = await getApprovedPlans();
    approval['status'] = 'approved';
    approval['decided_at'] = DateTime.now().toIso8601String();
    approved.add(approval);
    await prefs.setString(_approvedKey, jsonEncode(approved));

    // 2. حفظ قائمة الانتظار المحدّثة
    await prefs.setString(_pendingKey, jsonEncode(pending));

    // 3. إشعار للمختص
    await _addNotification(
      forRole: 'specialist',
      title: '✅ تم اعتماد الخطة من الوزارة',
      body:
          'خطة الطفل ${approval['child_name']} تمت الموافقة عليها من الوزارة',
      type: 'plan_approved',
    );

    // 4. إشعار للمعلم (إذا كان هناك معلم معيّن)
    if (approval['teacher_id'] != null) {
      await _addNotification(
        forRole: 'teacher',
        title: '📚 خطة تعليمية جديدة معتمدة',
        body:
            'تم اعتماد خطة الطفل ${approval['child_name']} من الوزارة — يمكنك الآن تطبيقها',
        type: 'plan_approved',
      );
    }

    // 5. محاولة إرسال للـ Backend
    try {
      await ApiService.authPost('/ministry/approvals/$approvalId/approve', {});
    } catch (_) {}
  }

  // ===== الوزارة ترفض طلباً =====
  static Future<void> reject({
    required String approvalId,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await getPendingApprovals();

    final index = pending.indexWhere((p) => p['id'] == approvalId);
    if (index == -1) return;

    final approval = pending.removeAt(index);

    // 1. إضافة لقائمة المرفوضة
    final rejected = await getRejectedPlans();
    approval['status'] = 'rejected';
    approval['decided_at'] = DateTime.now().toIso8601String();
    approval['rejection_reason'] = reason ?? 'لم يتم تحديد السبب';
    rejected.add(approval);
    await prefs.setString(_rejectedKey, jsonEncode(rejected));

    // 2. حفظ قائمة الانتظار المحدّثة
    await prefs.setString(_pendingKey, jsonEncode(pending));

    // 3. إشعار للمختص
    await _addNotification(
      forRole: 'specialist',
      title: '❌ تم رفض الخطة من الوزارة',
      body:
          'خطة الطفل ${approval['child_name']} تم رفضها${reason != null ? ': $reason' : ''}',
      type: 'plan_rejected',
    );

    // 4. محاولة إرسال للـ Backend
    try {
      await ApiService.authPost('/ministry/approvals/$approvalId/reject', {
        'reason': reason,
      });
    } catch (_) {}
  }

  // ===== جلب الخطط المعتمدة (للمعلم) =====
  static Future<List<Map<String, dynamic>>> getApprovedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_approvedKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ===== جلب الخطط المرفوضة (للمختص) =====
  static Future<List<Map<String, dynamic>>> getRejectedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rejectedKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ===== هل خطة هذا الطفل معتمدة؟ (للمعلم) =====
  static Future<Map<String, dynamic>?> getApprovedPlanForChild(
      int childId) async {
    final approved = await getApprovedPlans();
    try {
      return approved.firstWhere((p) => p['child_id'] == childId);
    } catch (_) {
      return null;
    }
  }

  // ===== إدارة الإشعارات الخاصة بالموافقات =====
  static Future<void> _addNotification({
    required String forRole,
    required String title,
    required String body,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    final list = raw != null && raw.isNotEmpty ? jsonDecode(raw) as List : [];

    list.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'for_role': forRole,
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_notificationsKey, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getNotificationsForRole(
      String role) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null || raw.isEmpty) return [];
    final all = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return all.where((n) => n['for_role'] == role).toList();
  }

  static Future<void> markNotificationRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null || raw.isEmpty) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    for (final n in list) {
      if (n['id'] == id) n['is_read'] = true;
    }
    await prefs.setString(_notificationsKey, jsonEncode(list));
  }

  static Future<int> getUnreadCountForRole(String role) async {
    final notifs = await getNotificationsForRole(role);
    return notifs.where((n) => n['is_read'] != true).length;
  }
 

// ===== جلب كل تقييمات مختص معيّن مع حالتها =====
static Future<List<Map<String, dynamic>>> getSubmissionsForChild(
    int childId) async {
  final prefs = await SharedPreferences.getInstance();

  final pending = await getPendingApprovals();
  final approved = await getApprovedPlans();
  final rejected = await getRejectedPlans();

  final all = <Map<String, dynamic>>[
    ...pending.where((p) => p['child_id'] == childId),
    ...approved.where((p) => p['child_id'] == childId),
    ...rejected.where((p) => p['child_id'] == childId),
  ];
  all.sort((a, b) {
    final da = DateTime.tryParse(a['submitted_at']?.toString() ?? '') ??
        DateTime(2000);
    final db = DateTime.tryParse(b['submitted_at']?.toString() ?? '') ??
        DateTime(2000);
    return db.compareTo(da);
  });
  return all;
}

// ===== حالة التقييم لطفل معيّن (pending/approved/rejected/none) =====
static Future<String> getApprovalStatusForChild(int childId) async {
  final pending = await getPendingApprovals();
  if (pending.any((p) => p['child_id'] == childId)) return 'pending';

  final approved = await getApprovedPlans();
  if (approved.any((p) => p['child_id'] == childId)) return 'approved';

  final rejected = await getRejectedPlans();
  if (rejected.any((p) => p['child_id'] == childId)) return 'rejected';

  return 'none';
}
}