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

  testWidgets('S20 AppBar respects the status-bar inset and both actions',
      (tester) async {
    var backCount = 0;
    var refreshCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            padding: EdgeInsets.only(top: 30),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: CaseDiscussionHeaderS20(
                onBack: () => backCount++,
                onRefresh: () => refreshCount++,
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    final title = find.text('دراسات الحالة');
    expect(title, findsOneWidget);
    expect(tester.getTopLeft(title).dy, greaterThan(30));
    expect(find.byTooltip('رجوع'), findsOneWidget);
    expect(find.byTooltip('تحديث دراسات الحالة'), findsOneWidget);

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pump();
    expect(backCount, 1);
    await tester.tap(find.byTooltip('تحديث دراسات الحالة'));
    await tester.pump();
    expect(refreshCount, 1);
  });
}
