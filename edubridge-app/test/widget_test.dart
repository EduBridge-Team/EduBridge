// اختبارات بدء التطبيق واستعادة الجلسة المحفوظة.
import 'package:edubridge_app/screens/admin/admin_screen.dart' show AdminScreen;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edubridge_app/main.dart' as app;
import 'package:edubridge_app/services/api_service.dart';
import 'package:edubridge_app/utils/home_router.dart';

void main() {
  testWidgets('المستخدم الضيف يرى الشاشة الترحيبية',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const app.EduBridgeApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('معاً ندعم تقدُّمه'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
  });

  test('الجلسة المحفوظة تحل إلى واجهة الدور الصحيح', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'saved-token',
      'role': 'admin',
      'name': 'Admin',
      'userId': 1,
    });

    expect(await ApiService.getToken(), 'saved-token');
    final destination = await homeScreenForRole();
    expect(destination, isA<AdminScreen>());
  });
}
