import 'package:edubridge_app/screens/support_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shared support opens as a dialog and validates inputs',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => SupportSheet.show(context),
                  child: const Text('فتح الدعم'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح الدعم'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('تواصل مع الدعم الفني'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('إرسال'), findsOneWidget);

    await tester.tap(find.text('إرسال'));
    await tester.pump();

    expect(find.text('الرجاء تعبئة الموضوع والرسالة'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
