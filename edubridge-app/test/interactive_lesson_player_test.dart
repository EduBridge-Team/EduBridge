import 'package:edubridge_app/models/interactive_lesson.dart';
import 'package:edubridge_app/screens/interactive_lesson/interactive_lesson_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lesson = InteractiveLesson(
    id: 'lesson-1',
    subject: 'arabic',
    title: 'درس الحروف',
    objective: 'تمييز الألف',
    steps: [
      LessonExplanation('intro', 'تعرف على الألف'),
      LessonSingleChoice('question', 'اختر الألف', [
        LessonOption('a', 'أ'),
        LessonOption('b', 'ب'),
      ], 'a'),
    ],
  );

  testWidgets('progresses through explanation and correct answer', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InteractiveLessonPlayer(lesson: lesson),
    ));
    expect(find.text('تعرف على الألف'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('اختر الألف'), findsOneWidget);
    await tester.tap(find.text('أ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تحقق من الإجابة'));
    await tester.pumpAndSettle();
    expect(find.text('أحسنت! إجابة صحيحة.'), findsOneWidget);
    await tester.tap(find.text('إنهاء الدرس'));
    await tester.pumpAndSettle();
    expect(find.text('أكملت الدرس! أحسنت.'), findsOneWidget);
  });

  testWidgets('wrong answer offers retry without allowing next', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InteractiveLessonPlayer(lesson: lesson),
    ));
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تحقق من الإجابة'));
    await tester.pumpAndSettle();
    expect(find.text('حاول مرة أخرى'), findsWidgets);
    expect(find.text('إنهاء الدرس'), findsNothing);
  });
}
