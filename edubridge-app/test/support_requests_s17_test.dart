import 'package:edubridge_app/screens/learning_support_requests/learning_support_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S17 displays the true empty-state illustration and text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SpecialistSupportEmptyState(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('لا توجد طلبات حالياً'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    final title = tester.widget<Text>(find.text('لا توجد طلبات حالياً'));
    expect(title.style?.fontWeight, FontWeight.w800);
  });
}
