// اختبار تكامل على الجهاز الحقيقي: تسجيل الدخول بحساب المعلّم
// يمرّ عبر الواجهة الفعلية على المنفذ 3000 من خلال الكابل
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edubridge_app/main.dart' as app;

// ينتظر ظهور عنصر بدل الانتظار الكامل، لأن مؤشر التحميل يمنع الاستقرار — pumpAndSettle
Future<bool> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('تسجيل الدخول بحساب المعلّم يصل للشاشة الرئيسية',
      (tester) async {
    // نبدأ بلا توكن محفوظ حتى تظهر شاشة الدخول دائماً
    SharedPreferences.setMockInitialValues({});

    app.main();
    await tester.pump(const Duration(seconds: 1));

    // شاشة الدخول ظاهرة
    final loginBtn = find.widgetWithText(ElevatedButton, 'دخول');
    expect(await pumpUntilFound(tester, loginBtn), true,
        reason: 'شاشة الدخول لم تظهر');

    // إدخال بيانات الحساب التجريبي
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'teacher@edu.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.pump(const Duration(milliseconds: 300));

    // ضغط زر الدخول
    await tester.tap(loginBtn);

    // ننتظر رد السيرفر والانتقال للشاشة الرئيسية
    final welcome = find.textContaining('مرحباً');
    expect(await pumpUntilFound(tester, welcome), true,
        reason: 'لم تظهر الشاشة الرئيسية بعد تسجيل الدخول');

    // زر «الأطفال» موجود في الشاشة الرئيسية
    expect(find.text('الأطفال'), findsOneWidget);
  });
}
