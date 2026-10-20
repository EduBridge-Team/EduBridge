import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/utils/notification_presentation.dart';
import 'package:flutter/widgets.dart';

void main() {
  const titles = <String, String>{
    "تمت إضافة طفل": "Child added",
    "تقييم جديد للطفل": "New child evaluation",
    "تقييم جديد": "New evaluation",
    "تم تعيين معلّم": "Teacher assigned",
    "تمت إضافتك لفريق دعم تعليمي": "Added to a learning support team",
    "درس جديد": "New lesson",
    "واجب جديد": "New homework",
    "تم تسليم واجب": "Homework submitted",
    "تم تسليم واجب متأخر": "Homework submitted late",
    "تم تقييم الواجب": "Homework graded",
    "تقرير أسبوعي جديد": "New weekly report",
    "متابعة جديدة من المختص": "New specialist progress update",
    "تقييم جديد للخطة": "New plan evaluation",
    "تم تحديد اجتماع دعم تعليمي": "Learning support meeting scheduled",
    "تم تحديد موعد جلسة الدعم التعليمي": "Learning support session scheduled",
    "اكتملت جلسة الدعم التعليمي": "Learning support session completed",
    "طلب دعم تعليمي جديد": "New learning support request",
    "تم إلغاء طلب الدعم التعليمي": "Learning support request cancelled",
    "توصية بدعم تعليمي": "Learning support recommendation",
    "اقتراح متابعة جديد": "New follow-up suggestion",
    "تم قبول اقتراح المتابعة": "Follow-up suggestion accepted",
    "تم رفض اقتراح المتابعة": "Follow-up suggestion rejected",
    "تم تأكيد المختص": "Specialist confirmed",
    "تحديث اقتراح المختص": "Specialist suggestion updated",
    "دراسة حالة جديدة": "New case study",
    "طلب دراسة حالة جديد": "New case study request",
    "توصية جديدة على دراسة الحالة": "New case study recommendation",
    "رسالة جديدة في دراسة حالة": "New case study message",
    "رسالة جديدة": "New message",
    "تحديث على طلب الدعم": "Support request updated",
    "تم توثيق حسابك": "Your account has been verified",
    "تم اعتماد هويتك": "Your identity has been approved",
    "تم رفض هويتك": "Your identity has been rejected",
    "تم توثيق بيانات الطفل": "Child details verified",
    "تم رفض توثيق بيانات الطفل": "Child verification rejected",
    "لم يتم توثيق بيانات الطفل": "Child details not verified",
    "اكتمل توثيق حسابك": "Your account verification is complete",
    "تم اعتماد شهادتك": "Your certificate has been approved",
    "تم رفض شهادتك": "Your certificate has been rejected",
    "خطة تعليمية بانتظار المراجعة": "Educational plan awaiting review",
    "تم اعتماد الدرس": "Lesson approved",
    "تم رفض الدرس": "Lesson rejected",
    "تم اعتماد الخطة": "Plan approved",
    "تم رفض الخطة": "Plan rejected",
    "تنبيه غياب": "Absence alert",
    "تنبيه تأخر": "Lateness alert",
    "درس مقترح لطفلك": "Suggested lesson for your child",
  };
  late AppLocalizations arabic;
  late AppLocalizations english;
  setUpAll(() async {
    arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    english = await AppLocalizations.delegate.load(const Locale('en'));
  });
  for (final entry in titles.entries) {
    test('localizes ${entry.value} without changing the payload', () {
      for (final bodyKey in ['body', 'message']) {
        final notification = <String, dynamic>{
          'title': entry.key,
          bodyKey: 'نص أصلي English 123',
          'type': 'verification',
        };
        final original = Map<String, dynamic>.from(notification);
        expect(NotificationPresentation.title(notification, english), entry.value);
        expect(notification, original);
        notification['title'] = entry.value;
        expect(NotificationPresentation.title(notification, arabic), entry.key);
        expect(notification[bodyKey], original[bodyKey]);
      }
    });
  }
  test('preserves custom titles even for a recognized notification type', () {
    expect(NotificationPresentation.title({
      'title': 'عنوان خاص', 'type': 'verification',
    }, english), 'عنوان خاص');
  });
  test('preserves the original emergency name across locale changes', () {
    final notification = <String, dynamic>{'title': '🚨 تنبيه طوارئ: محمود'};
    expect(NotificationPresentation.title(notification, english), '🚨 Emergency alert: محمود');
    notification['title'] = '🚨 Emergency alert: محمود';
    expect(NotificationPresentation.title(notification, arabic), '🚨 تنبيه طوارئ: محمود');
  });
  test('uses a localized fallback for missing titles', () {
    expect(NotificationPresentation.title({}, english), english.notificationDetails);
    expect(NotificationPresentation.title({}, arabic), arabic.notificationDetails);
  });
}
