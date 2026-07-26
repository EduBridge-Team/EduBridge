// اختبار أساسي: التطبيق يشتغل ويعرض شاشة البداية بدون أخطاء
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edubridge_app/main.dart';

void main() {
  testWidgets('التطبيق يبنى ويعرض شاشة الدخول', (WidgetTester tester) async {
    // تهيئة تخزين وهمي: لا يوجد توكن محفوظ، فتظهر شاشة الدخول
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EduBridgeApp());
    await tester.pumpAndSettle();

    // شاشة الدخول تعرض اسم التطبيق وزر الدخول
    expect(find.text('EduBridge'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });
}
