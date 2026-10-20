import '../l10n/generated/app_localizations.dart';

/// Localizes recognized system titles without changing notification data.
class NotificationPresentation {
  static String title(Map<String, dynamic> notification, AppLocalizations strings) {
    final raw = (notification['title'] ?? '').toString();
    const emergencyPrefix = '🚨 تنبيه طوارئ: ';
    const englishEmergencyPrefix = '🚨 Emergency alert: ';
    for (final prefix in [emergencyPrefix, englishEmergencyPrefix]) {
      if (raw.startsWith(prefix)) {
        return strings.notificationTitleEmergencyFor(raw.substring(prefix.length));
      }
    }
    return switch (raw) {
      "تمت إضافة طفل" || "Child added" => strings.notificationTitleChildAdded,
      "تقييم جديد للطفل" || "New child evaluation" => strings.notificationTitleChildEvaluation,
      "تقييم جديد" || "New evaluation" => strings.notificationTitleEvaluation,
      "تم تعيين معلّم" || "Teacher assigned" => strings.notificationTitleTeacherAssigned,
      "تمت إضافتك لفريق دعم تعليمي" || "Added to a learning support team" => strings.notificationTitleCareTeam,
      "درس جديد" || "New lesson" => strings.notificationTitleLesson,
      "واجب جديد" || "New homework" => strings.notificationTitleHomework,
      "تم تسليم واجب" || "Homework submitted" => strings.notificationTitleHomeworkSubmitted,
      "تم تسليم واجب متأخر" || "Homework submitted late" => strings.notificationTitleHomeworkLate,
      "تم تقييم الواجب" || "Homework graded" => strings.notificationTitleHomeworkGraded,
      "تقرير أسبوعي جديد" || "New weekly report" => strings.notificationTitleWeeklyReport,
      "متابعة جديدة من المختص" || "New specialist progress update" => strings.notificationTitleProgress,
      "تقييم جديد للخطة" || "New plan evaluation" => strings.notificationTitlePlanEvaluation,
      "تم تحديد اجتماع دعم تعليمي" || "Learning support meeting scheduled" => strings.notificationTitleMeeting,
      "تم تحديد موعد جلسة الدعم التعليمي" || "Learning support session scheduled" => strings.notificationTitleSession,
      "اكتملت جلسة الدعم التعليمي" || "Learning support session completed" => strings.notificationTitleSessionCompleted,
      "طلب دعم تعليمي جديد" || "New learning support request" => strings.notificationTitleSupportRequest,
      "تم إلغاء طلب الدعم التعليمي" || "Learning support request cancelled" => strings.notificationTitleSupportCancelled,
      "توصية بدعم تعليمي" || "Learning support recommendation" => strings.notificationTitleSupportRecommendation,
      "اقتراح متابعة جديد" || "New follow-up suggestion" => strings.notificationTitleSuggestion,
      "تم قبول اقتراح المتابعة" || "Follow-up suggestion accepted" => strings.notificationTitleSuggestionAccepted,
      "تم رفض اقتراح المتابعة" || "Follow-up suggestion rejected" => strings.notificationTitleSuggestionRejected,
      "تم تأكيد المختص" || "Specialist confirmed" => strings.notificationTitleSpecialistConfirmed,
      "تحديث اقتراح المختص" || "Specialist suggestion updated" => strings.notificationTitleSpecialistUpdated,
      "دراسة حالة جديدة" || "New case study" => strings.notificationTitleCase,
      "طلب دراسة حالة جديد" || "New case study request" => strings.notificationTitleCaseRequest,
      "توصية جديدة على دراسة الحالة" || "New case study recommendation" => strings.notificationTitleCaseRecommendation,
      "رسالة جديدة في دراسة حالة" || "New case study message" => strings.notificationTitleCaseMessage,
      "رسالة جديدة" || "New message" => strings.notificationTitleMessage,
      "تحديث على طلب الدعم" || "Support request updated" => strings.notificationTitleSupportUpdate,
      "تم توثيق حسابك" || "Your account has been verified" => strings.notificationTitleAccountVerified,
      "تم اعتماد هويتك" || "Your identity has been approved" => strings.notificationTitleIdentityApproved,
      "تم رفض هويتك" || "Your identity has been rejected" => strings.notificationTitleIdentityRejected,
      "تم توثيق بيانات الطفل" || "Child details verified" => strings.notificationTitleChildVerified,
      "تم رفض توثيق بيانات الطفل" || "Child verification rejected" => strings.notificationTitleChildRejected,
      "لم يتم توثيق بيانات الطفل" || "Child details not verified" => strings.notificationTitleChildUnverified,
      "اكتمل توثيق حسابك" || "Your account verification is complete" => strings.notificationTitleVerificationCompleted,
      "تم اعتماد شهادتك" || "Your certificate has been approved" => strings.notificationTitleCertificateApproved,
      "تم رفض شهادتك" || "Your certificate has been rejected" => strings.notificationTitleCertificateRejected,
      "خطة تعليمية بانتظار المراجعة" || "Educational plan awaiting review" => strings.notificationTitlePlanReview,
      "تم اعتماد الدرس" || "Lesson approved" => strings.notificationTitleLessonApproved,
      "تم رفض الدرس" || "Lesson rejected" => strings.notificationTitleLessonRejected,
      "تم اعتماد الخطة" || "Plan approved" => strings.notificationTitlePlanApproved,
      "تم رفض الخطة" || "Plan rejected" => strings.notificationTitlePlanRejected,
      "تنبيه غياب" || "Absence alert" => strings.notificationTitleAbsence,
      "تنبيه تأخر" || "Lateness alert" => strings.notificationTitleLateness,
      "درس مقترح لطفلك" || "Suggested lesson for your child" => strings.notificationTitleLessonRecommendation,
      _ => raw.isEmpty ? strings.notificationDetails : raw,
    };
  }
}
