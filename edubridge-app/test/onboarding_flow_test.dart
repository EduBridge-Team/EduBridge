import 'package:edubridge_app/screens/welcome_screen.dart';
import 'package:edubridge_app/services/onboarding_service.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showWelcome(WidgetTester tester, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }
  await tester.pumpWidget(MaterialApp(theme: buildJisrTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
    home: const WelcomeScreen()));
  await tester.pump();
}

Future<void> tapLabel(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('all four reference screens are reachable in order', (tester) async {
    await showWelcome(tester, size: const Size(390, 844));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    expect(find.text('الخطوة 1 من 3'), findsOneWidget);
    expect(find.text('تعليم يتكيف مع كل طفل'), findsOneWidget);
    expect(find.text('السابق'), findsNothing);
    await tapLabel(tester, 'التالي');
    expect(find.text('الخطوة 2 من 3'), findsOneWidget);
    expect(find.text('أسرة ومعلم ومختص\nفي مكان واحد'), findsOneWidget);
    await tapLabel(tester, 'التالي');
    expect(find.text('الخطوة 3 من 3'), findsOneWidget);
    expect(find.text('بيئة آمنة ومريحة'), findsOneWidget);
    await tapLabel(tester, 'ابدأ');
    expect(find.byKey(const ValueKey('onboarding-welcome')), findsOneWidget);
    expect(find.text('تعليم ذكي\nوشامل\nلكل طفل'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    expect(find.text('تعرّف على EduBridge'), findsOneWidget);
    // Completing the tour keeps both account choices available.
    expect(await OnboardingService.hasSeen(), isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('previous and skip preserve the account landing page', (tester) async {
    await showWelcome(tester);
    await tapLabel(tester, 'التالي');
    await tapLabel(tester, 'السابق');
    expect(find.text('الخطوة 1 من 3'), findsOneWidget);
    await tapLabel(tester, 'تخطي');
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
  });
  testWidgets('about content remains available and the tour can be replayed', (tester) async {
    await showWelcome(tester, size: const Size(390, 844));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tapLabel(tester, 'تخطي');
    await tapLabel(tester, 'تعرّف على EduBridge');
    expect(find.text('رؤية بلا حدود'), findsOneWidget);
    await tapLabel(tester, 'اكتشف تجربة EduBridge');
    expect(find.text('الخطوة 1 من 3'), findsOneWidget);
    await tapLabel(tester, 'التالي');
    await tapLabel(tester, 'التالي');
    await tapLabel(tester, 'ابدأ');
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
  testWidgets('onboarding remains usable on a small phone', (tester) async {
    await showWelcome(tester, size: const Size(320, 568));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tapLabel(tester, 'التالي');
    await tapLabel(tester, 'التالي');
    await tapLabel(tester, 'ابدأ');
    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
