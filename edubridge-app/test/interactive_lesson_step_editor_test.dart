import 'package:edubridge_app/models/interactive_lesson.dart';
import 'package:edubridge_app/screens/interactive_lesson/interactive_lesson_step_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lesson = InteractiveLesson(
    id: 'example', subject: 'arabic', title: 'حروف', objective: 'التعرف على الحروف',
    steps: [LessonExplanation('intro', 'حرف الألف')],
  );

  testWidgets('educator can add an explanation and preview without publishing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractiveLessonStepEditor(template: lesson)));
    expect(find.text('التغييرات للمعاينة فقط ولا تُحفظ أو تُنشر.'), findsOneWidget);
    await tester.tap(find.text('إضافة شرح'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('lesson-step-explanation-input')), 'شرح جديد');
    await tester.tap(find.text('إضافة').last);
    await tester.pumpAndSettle();
    expect(find.text('شرح جديد'), findsOneWidget);
    await tester.tap(find.text('معاينة'));
    await tester.pumpAndSettle();
    expect(find.text('حرف الألف'), findsOneWidget);
  });

  testWidgets('editor prevents preview when all steps removed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractiveLessonStepEditor(template: lesson)));
    await tester.tap(find.byTooltip('حذف الخطوة'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'معاينة'));
    expect(button.onPressed, isNull);
  });
}
