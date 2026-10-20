import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/utils/notification_presentation.dart';
import 'package:flutter/widgets.dart';

void main() {
  test("localizes ChildAdded", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تمت إضافة طفل", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Child added");
    expect(notification, original);
    notification["title"] = "Child added";
    expect(NotificationPresentation.title(notification, arabic), "تمت إضافة طفل");
  });
  test("localizes ChildEvaluation", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تقييم جديد للطفل", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New child evaluation");
    expect(notification, original);
    notification["title"] = "New child evaluation";
    expect(NotificationPresentation.title(notification, arabic), "تقييم جديد للطفل");
  });
  test("localizes Evaluation", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تقييم جديد", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New evaluation");
    expect(notification, original);
    notification["title"] = "New evaluation";
    expect(NotificationPresentation.title(notification, arabic), "تقييم جديد");
  });
  test("localizes TeacherAssigned", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم تعيين معلّم", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Teacher assigned");
    expect(notification, original);
    notification["title"] = "Teacher assigned";
    expect(NotificationPresentation.title(notification, arabic), "تم تعيين معلّم");
  });
  test("localizes CareTeam", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تمت إضافتك لفريق دعم تعليمي", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Added to a learning support team");
    expect(notification, original);
    notification["title"] = "Added to a learning support team";
    expect(NotificationPresentation.title(notification, arabic), "تمت إضافتك لفريق دعم تعليمي");
  });
  test("localizes Lesson", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "درس جديد", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New lesson");
    expect(notification, original);
    notification["title"] = "New lesson";
    expect(NotificationPresentation.title(notification, arabic), "درس جديد");
  });
  test("localizes Homework", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "واجب جديد", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New homework");
    expect(notification, original);
    notification["title"] = "New homework";
    expect(NotificationPresentation.title(notification, arabic), "واجب جديد");
  });
  test("localizes HomeworkSubmitted", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم تسليم واجب", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Homework submitted");
    expect(notification, original);
    notification["title"] = "Homework submitted";
    expect(NotificationPresentation.title(notification, arabic), "تم تسليم واجب");
  });
  test("localizes HomeworkLate", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم تسليم واجب متأخر", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Homework submitted late");
    expect(notification, original);
    notification["title"] = "Homework submitted late";
    expect(NotificationPresentation.title(notification, arabic), "تم تسليم واجب متأخر");
  });
  test("localizes HomeworkGraded", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم تقييم الواجب", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Homework graded");
    expect(notification, original);
    notification["title"] = "Homework graded";
    expect(NotificationPresentation.title(notification, arabic), "تم تقييم الواجب");
  });
  test("localizes WeeklyReport", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تقرير أسبوعي جديد", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New weekly report");
    expect(notification, original);
    notification["title"] = "New weekly report";
    expect(NotificationPresentation.title(notification, arabic), "تقرير أسبوعي جديد");
  });
  test("localizes Progress", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "متابعة جديدة من المختص", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New specialist progress update");
    expect(notification, original);
    notification["title"] = "New specialist progress update";
    expect(NotificationPresentation.title(notification, arabic), "متابعة جديدة من المختص");
  });
  test("localizes PlanEvaluation", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تقييم جديد للخطة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New plan evaluation");
    expect(notification, original);
    notification["title"] = "New plan evaluation";
    expect(NotificationPresentation.title(notification, arabic), "تقييم جديد للخطة");
  });
  test("localizes Meeting", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم تحديد اجتماع دعم تعليمي", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Learning support meeting scheduled");
    expect(notification, original);
    notification["title"] = "Learning support meeting scheduled";
    expect(NotificationPresentation.title(notification, arabic), "تم تحديد اجتماع دعم تعليمي");
  });
  test("localizes Session", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم تحديد موعد جلسة الدعم التعليمي", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Learning support session scheduled");
    expect(notification, original);
    notification["title"] = "Learning support session scheduled";
    expect(NotificationPresentation.title(notification, arabic), "تم تحديد موعد جلسة الدعم التعليمي");
  });
  test("localizes SessionCompleted", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "اكتملت جلسة الدعم التعليمي", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Learning support session completed");
    expect(notification, original);
    notification["title"] = "Learning support session completed";
    expect(NotificationPresentation.title(notification, arabic), "اكتملت جلسة الدعم التعليمي");
  });
  test("localizes SupportRequest", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "طلب دعم تعليمي جديد", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New learning support request");
    expect(notification, original);
    notification["title"] = "New learning support request";
    expect(NotificationPresentation.title(notification, arabic), "طلب دعم تعليمي جديد");
  });
  test("localizes SupportCancelled", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم إلغاء طلب الدعم التعليمي", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Learning support request cancelled");
    expect(notification, original);
    notification["title"] = "Learning support request cancelled";
    expect(NotificationPresentation.title(notification, arabic), "تم إلغاء طلب الدعم التعليمي");
  });
  test("localizes SupportRecommendation", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "توصية بدعم تعليمي", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Learning support recommendation");
    expect(notification, original);
    notification["title"] = "Learning support recommendation";
    expect(NotificationPresentation.title(notification, arabic), "توصية بدعم تعليمي");
  });
  test("localizes Suggestion", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "اقتراح متابعة جديد", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New follow-up suggestion");
    expect(notification, original);
    notification["title"] = "New follow-up suggestion";
    expect(NotificationPresentation.title(notification, arabic), "اقتراح متابعة جديد");
  });
  test("localizes SuggestionAccepted", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم قبول اقتراح المتابعة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Follow-up suggestion accepted");
    expect(notification, original);
    notification["title"] = "Follow-up suggestion accepted";
    expect(NotificationPresentation.title(notification, arabic), "تم قبول اقتراح المتابعة");
  });
  test("localizes SuggestionRejected", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم رفض اقتراح المتابعة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Follow-up suggestion rejected");
    expect(notification, original);
    notification["title"] = "Follow-up suggestion rejected";
    expect(NotificationPresentation.title(notification, arabic), "تم رفض اقتراح المتابعة");
  });
  test("localizes SpecialistConfirmed", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم تأكيد المختص", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Specialist confirmed");
    expect(notification, original);
    notification["title"] = "Specialist confirmed";
    expect(NotificationPresentation.title(notification, arabic), "تم تأكيد المختص");
  });
  test("localizes SpecialistUpdated", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تحديث اقتراح المختص", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Specialist suggestion updated");
    expect(notification, original);
    notification["title"] = "Specialist suggestion updated";
    expect(NotificationPresentation.title(notification, arabic), "تحديث اقتراح المختص");
  });
  test("localizes Case", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "دراسة حالة جديدة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New case study");
    expect(notification, original);
    notification["title"] = "New case study";
    expect(NotificationPresentation.title(notification, arabic), "دراسة حالة جديدة");
  });
  test("localizes CaseRequest", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "طلب دراسة حالة جديد", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New case study request");
    expect(notification, original);
    notification["title"] = "New case study request";
    expect(NotificationPresentation.title(notification, arabic), "طلب دراسة حالة جديد");
  });
  test("localizes CaseRecommendation", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "توصية جديدة على دراسة الحالة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New case study recommendation");
    expect(notification, original);
    notification["title"] = "New case study recommendation";
    expect(NotificationPresentation.title(notification, arabic), "توصية جديدة على دراسة الحالة");
  });
  test("localizes CaseMessage", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "رسالة جديدة في دراسة حالة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New case study message");
    expect(notification, original);
    notification["title"] = "New case study message";
    expect(NotificationPresentation.title(notification, arabic), "رسالة جديدة في دراسة حالة");
  });
  test("localizes Message", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "رسالة جديدة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "New message");
    expect(notification, original);
    notification["title"] = "New message";
    expect(NotificationPresentation.title(notification, arabic), "رسالة جديدة");
  });
  test("localizes SupportUpdate", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تحديث على طلب الدعم", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Support request updated");
    expect(notification, original);
    notification["title"] = "Support request updated";
    expect(NotificationPresentation.title(notification, arabic), "تحديث على طلب الدعم");
  });
  test("localizes AccountVerified", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم توثيق حسابك", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Your account has been verified");
    expect(notification, original);
    notification["title"] = "Your account has been verified";
    expect(NotificationPresentation.title(notification, arabic), "تم توثيق حسابك");
  });
  test("localizes IdentityApproved", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم اعتماد هويتك", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Your identity has been approved");
    expect(notification, original);
    notification["title"] = "Your identity has been approved";
    expect(NotificationPresentation.title(notification, arabic), "تم اعتماد هويتك");
  });
  test("localizes IdentityRejected", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم رفض هويتك", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Your identity has been rejected");
    expect(notification, original);
    notification["title"] = "Your identity has been rejected";
    expect(NotificationPresentation.title(notification, arabic), "تم رفض هويتك");
  });
  test("localizes ChildVerified", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم توثيق بيانات الطفل", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Child details verified");
    expect(notification, original);
    notification["title"] = "Child details verified";
    expect(NotificationPresentation.title(notification, arabic), "تم توثيق بيانات الطفل");
  });
  test("localizes ChildRejected", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم رفض توثيق بيانات الطفل", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Child verification rejected");
    expect(notification, original);
    notification["title"] = "Child verification rejected";
    expect(NotificationPresentation.title(notification, arabic), "تم رفض توثيق بيانات الطفل");
  });
  test("localizes ChildUnverified", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "لم يتم توثيق بيانات الطفل", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Child details not verified");
    expect(notification, original);
    notification["title"] = "Child details not verified";
    expect(NotificationPresentation.title(notification, arabic), "لم يتم توثيق بيانات الطفل");
  });
  test("localizes VerificationCompleted", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "اكتمل توثيق حسابك", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Your account verification is complete");
    expect(notification, original);
    notification["title"] = "Your account verification is complete";
    expect(NotificationPresentation.title(notification, arabic), "اكتمل توثيق حسابك");
  });
  test("localizes CertificateApproved", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم اعتماد شهادتك", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Your certificate has been approved");
    expect(notification, original);
    notification["title"] = "Your certificate has been approved";
    expect(NotificationPresentation.title(notification, arabic), "تم اعتماد شهادتك");
  });
  test("localizes CertificateRejected", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم رفض شهادتك", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Your certificate has been rejected");
    expect(notification, original);
    notification["title"] = "Your certificate has been rejected";
    expect(NotificationPresentation.title(notification, arabic), "تم رفض شهادتك");
  });
  test("localizes PlanReview", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "خطة تعليمية بانتظار المراجعة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Educational plan awaiting review");
    expect(notification, original);
    notification["title"] = "Educational plan awaiting review";
    expect(NotificationPresentation.title(notification, arabic), "خطة تعليمية بانتظار المراجعة");
  });
  test("localizes LessonApproved", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم اعتماد الدرس", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Lesson approved");
    expect(notification, original);
    notification["title"] = "Lesson approved";
    expect(NotificationPresentation.title(notification, arabic), "تم اعتماد الدرس");
  });
  test("localizes LessonRejected", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم رفض الدرس", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Lesson rejected");
    expect(notification, original);
    notification["title"] = "Lesson rejected";
    expect(NotificationPresentation.title(notification, arabic), "تم رفض الدرس");
  });
  test("localizes PlanApproved", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم اعتماد الخطة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Plan approved");
    expect(notification, original);
    notification["title"] = "Plan approved";
    expect(NotificationPresentation.title(notification, arabic), "تم اعتماد الخطة");
  });
  test("localizes PlanRejected", () async {
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final notification = <String, dynamic>{"title": "تم رفض الخطة", "body": "نص أصلي English 123", "type": "custom"};
    final original = Map<String, dynamic>.from(notification);
    expect(NotificationPresentation.title(notification, english), "Plan rejected");
    expect(notification, original);
    notification["title"] = "Plan rejected";
    expect(NotificationPresentation.title(notification, arabic), "تم رفض الخطة");
  });
  test("preserves custom titles and emergency names", () async {
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(NotificationPresentation.title({"title": "عنوان خاص", "type": "verification"}, strings), "عنوان خاص");
    expect(NotificationPresentation.title({"title": "🚨 تنبيه طوارئ: محمود"}, strings), "🚨 Emergency alert: محمود");
    expect(NotificationPresentation.title({}, strings), strings.notificationDetails);
  });
}
