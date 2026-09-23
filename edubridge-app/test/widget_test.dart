// اختبارات بدء التطبيق واستعادة الجلسة المحفوظة.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edubridge_app/main.dart';

void main() {
  testWidgets('المستخدم الضيف يرى الشاشة الترحيبية',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EduBridgeApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('جسر التعليمي'), findsOneWidget);
    expect(find.text('🚀 ابدأ رحلتك التعليمية'), findsOneWidget);
  });

  testWidgets('الجلسة المحفوظة تتجاوز الشاشة الترحيبية',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'token': 'saved-token',
      'role': 'admin',
      'name': 'Admin',
      'userId': 1,
    });

    await tester.pumpWidget(const EduBridgeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('🚀 ابدأ رحلتك التعليمية'), findsNothing);
  });
}
