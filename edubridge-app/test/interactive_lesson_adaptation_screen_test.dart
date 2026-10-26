import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/models/interactive_lesson.dart';
import 'package:edubridge_app/screens/interactive_lesson/interactive_lesson_adaptation_screen.dart';

void main() {
  const template = InteractiveLesson(
    id: 'offline-template',
    subject: 'arabic',
    title: 'العنوان الأصلي',
    objective: 'النتاج الأصلي',
    steps: [LessonExplanation('s1', 'نص الشرح')],
  );

  testWidgets('adaptation edits a local copy without changing template', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InteractiveLessonAdaptationScreen(template: template),
    ));
    expect(find.textContaining('لن يتم حفظ التغييرات'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('adapt-lesson-title')), 'درس معدل');
    await tester.enterText(find.byKey(const ValueKey('adapt-lesson-objective')), 'نتاج معدل');
    expect(template.title, 'العنوان الأصلي');
    expect(template.objective, 'النتاج الأصلي');
    await tester.ensureVisible(find.byKey(const ValueKey('preview-adapted-lesson')));
    await tester.tap(find.byKey(const ValueKey('preview-adapted-lesson')));
    await tester.pumpAndSettle();
    expect(find.text('درس معدل'), findsWidgets);
  });

  testWidgets('blank title cannot open lesson player', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InteractiveLessonAdaptationScreen(template: template),
    ));
    await tester.enterText(find.byKey(const ValueKey('adapt-lesson-title')), ' ');
    await tester.ensureVisible(find.byKey(const ValueKey('preview-adapted-lesson')));
    await tester.tap(find.byKey(const ValueKey('preview-adapted-lesson')));
    await tester.pump();
    expect(find.text('أدخل عنوان الدرس والنتاج التعليمي.'), findsOneWidget);
    expect(find.byType(InteractiveLessonAdaptationScreen), findsOneWidget);
  });
}
