// خدمة إدارة موافقات الوزارة على تقييمات المختص
// - تحفظ محلياً (offline-first)
// - تُزامن مع الـ Backend عند توفّر الإنترنت
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ApprovalService {
  static const _pendingKey = 'pending_ministry_approvals';
  static const _approvedKey = 'approved_plans';
  static const _rejectedKey = 'rejected_plans';
  static const _notificationsKey = 'approval_notifications';

  // ═══════════════════════════════════════════════════════
  // 1. المختص يرسل تقييماً + خطة للوزارة
  // ═══════════════════════════════════════════════════════
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

    // 1. حفظ محلياً في قائمة الانتظار
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
      'synced_to_server': false,
    };
    pending.add(approval);
    await prefs.setString(_pendingKey, jsonEncode(pending));

    // 2. إشعار المختص
    await _addNotification(
      forRole: 'specialist',
      title: '📤 تم إرسال التقييم للوزارة',
      body: 'تقييم الطفل $childName قيد مراجعة الوزارة',
      type: 'plan_submitted',
    );

    // 3. محاولة الإرسال للـ Backend
    try {
      final serverRes = await ApiService.submitForMinistryApproval(
        childId: childId,
        evaluationId: evaluationId,
        educationalPlan: educationalPlan,
        cognitiveAssessment: cognitiveAssessment,
        motorAssessment: motorAssessment,
        emotionalAssessment: emotionalAssessment,
        socialAssessment: socialAssessment,
        recommendations: recommendations,
        teachingMethods: teachingMethods,
        teacherId: teacherId,
      );
      if (serverRes != null) {
        // تحديث القائمة المحلية بـ server_id
        final updated = await getPendingApprovals();
        final idx = updated.indexWhere((p) => p['id'] == approval['id']);
        if (idx != -1) {
          updated[idx]['server_id'] = serverRes['id'];
          updated[idx]['synced_to_server'] = true;
          await prefs.setString(_pendingKey, jsonEncode(updated));
        }
      }
    } catch (_) {
      // يُرسل لاحقاً عند عودة الإنترنت
    }
  }

  // ═══════════════════════════════════════════════════════
  // 2. جلب الطلبات المعلقة (للوزارة)
  // ═══════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ═══════════════════════════════════════════════════════
  // 3. الوزارة توافق على الطلب
  // ═══════════════════════════════════════════════════════
  static Future<void> approve({
    required String approvalId,
    required String specialistName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await getPendingApprovals();

    final index = pending.indexWhere((p) => p['id'] == approvalId);
    if (index == -1) return;

    final approval = pending.removeAt(index);

    // 1. نقل للقائمة المعتمدة
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
      body: 'خطة الطفل ${approval['child_name']} تمت الموافقة عليها',
      type: 'plan_approved',
    );

    // 4. إشعار للمعلم ليطبّق الخطة
    if (approval['teacher_id'] != null) {
      await _addNotification(
        forRole: 'teacher',
        title: '📚 خطة تعليمية جديدة معتمدة',
        body:
            'تم اعتماد خطة الطفل ${approval['child_name']} — يمكنك الآن تطبيقها',
        type: 'plan_approved',
      );
    }

    // 5. إرسال للـ Backend
    try {
      final serverId = approval['server_id'] ?? approval['id'];
      await ApiService.approveMinistryRequest(
        serverId is int ? serverId : int.tryParse(serverId.toString()) ?? 0,
      );
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════
  // 4. الوزارة ترفض الطلب
  // ═══════════════════════════════════════════════════════
  static Future<void> reject({
    required String approvalId,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await getPendingApprovals();

    final index = pending.indexWhere((p) => p['id'] == approvalId);
    if (index == -1) return;

    final approval = pending.removeAt(index);

    // 1. نقل للقائمة المرفوضة
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
          'خطة الطفل ${approval['child_name']} رُفضت${reason != null ? ': $reason' : ''}',
      type: 'plan_rejected',
    );

    // 4. إرسال للـ Backend
    try {
      final serverId = approval['server_id'] ?? approval['id'];
      await ApiService.rejectMinistryRequest(
        serverId is int ? serverId : int.tryParse(serverId.toString()) ?? 0,
        reason: reason,
      );
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════
  // 5. جلب الخطط المعتمدة (للمعلم)
  // ═══════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getApprovedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_approvedKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getRejectedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rejectedKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ═══════════════════════════════════════════════════════
  // 6. الاستعلامات
  // ═══════════════════════════════════════════════════════

  /// هل خطة هذا الطفل معتمدة؟ (للمعلم)
  static Future<Map<String, dynamic>?> getApprovedPlanForChild(
      int childId) async {
    final approved = await getApprovedPlans();
    try {
      return approved.firstWhere((p) => p['child_id'] == childId);
    } catch (_) {
      return null;
    }
  }

  /// حالة التقييم لطفل (pending/approved/rejected/none)
  static Future<String> getApprovalStatusForChild(int childId) async {
    final pending = await getPendingApprovals();
    if (pending.any((p) => p['child_id'] == childId)) return 'pending';

    final approved = await getApprovedPlans();
    if (approved.any((p) => p['child_id'] == childId)) return 'approved';

    final rejected = await getRejectedPlans();
    if (rejected.any((p) => p['child_id'] == childId)) return 'rejected';

    return 'none';
  }

  /// جلب كل تقييمات طفل معيّن مع حالتها
  static Future<List<Map<String, dynamic>>> getSubmissionsForChild(
      int childId) async {
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

  // ═══════════════════════════════════════════════════════
  // 7. إدارة الإشعارات
  // ═══════════════════════════════════════════════════════
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
}