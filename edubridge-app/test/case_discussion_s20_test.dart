import 'package:edubridge_app/screens/case_discussion/case_discussion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S20 empty case-studies view matches the reference content',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: CaseDiscussionEmptyS20()),
        ),
      ),
    );

    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.text('لا توجد دراسات حالة بعد'), findsOneWidget);
    expect(
      find.text('ابدأ دراسة جديدة للتعاون مع المختصين حول\nحالة الطفل.'),
      findsOneWidget,
    );
    expect(find.textContaining('نشطة ('), findsNothing);
    expect(find.textContaining('مكتملة ('), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    final heading = tester.widget<Text>(find.text('لا توجد دراسات حالة بعد'));
    expect(heading.style?.fontWeight, FontWeight.w800);
  });
}
