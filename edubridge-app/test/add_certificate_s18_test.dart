import 'package:edubridge_app/screens/add_certificate_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S18 centered specialist certificate dialog validates required fields',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AddCertificateSheet(
                    figmaS18: true,
                    onSaved: () {},
                  ),
                ),
                child: const Text('إضافة شهادة'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('إضافة شهادة'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('إضافة شهادة (إثبات أهلية)'), findsOneWidget);
    expect(find.byKey(const ValueKey('s18_certificate_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('s18_choose_certificate_file')), findsOneWidget);
    expect(find.text('ملف الشهادة (صورة أو PDF)'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('إرسال للمراجعة'), findsOneWidget);

    final cancelX = tester.getCenter(find.text('إلغاء')).dx;
    final sendX = tester.getCenter(find.text('إرسال للمراجعة')).dx;
    expect(cancelX, greaterThan(sendX));

    await tester.tap(find.byKey(const ValueKey('s18_submit_certificate')));
    await tester.pump();
    expect(find.text('عنوان الشهادة مطلوب'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('s18_certificate_title')),
      'شهادة تدريب',
    );
    await tester.tap(find.byKey(const ValueKey('s18_submit_certificate')));
    await tester.pump();
    expect(find.text('ملف الشهادة مطلوب'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
