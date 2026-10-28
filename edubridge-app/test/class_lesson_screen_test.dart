import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/class_lessons/class_lessons_screen.dart';
import 'curriculum_ui_support.dart';
import 'class_lesson_fixture.dart';

Future<void> chooseSection(WidgetTester tester, String name) async {
  final button = find.descendant(of: find.byKey(const ValueKey('class-lesson-section')), matching: find.byType(OutlinedButton));
  await tester.ensureVisible(button); await tester.tap(button); await tester.pumpAndSettle();
  final option = find.descendant(of: find.byType(SimpleDialog), matching: find.text(name));
  await tester.ensureVisible(option); await tester.tap(option); await tester.pumpAndSettle();
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('section results stay scoped $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = ClassLessonFixture();
        await tester.pumpWidget(curriculumHost(ClassLessonsScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        expect(find.text('طالب 1'), findsNothing);
        await chooseSection(tester, 'School 1 / 2026/2027 / A');
        expect(find.text('طالب 1'), findsOneWidget);
        expect(find.textContaining('0 / 10'), findsOneWidget);
        expect(find.textContaining('هدف الطالب 1'), findsOneWidget);
        await chooseSection(tester, 'School 2 / 2026/2027 / B');
        expect(find.text('طالب 1'), findsNothing); expect(find.text('طالب 2'), findsOneWidget);
        await resumeCurriculum(tester);
        expect(find.text('طالب 2'), findsNothing); expect(f.reads, 2);
        f.status = 403; await resumeCurriculum(tester);
        expect(find.text('طالب 1'), findsNothing); expect(find.text('طالب 2'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('source replacement drops selected class and cached students', (tester) async {
    final old = ClassLessonFixture(), next = ClassLessonFixture()..status = 404;
    await tester.pumpWidget(curriculumHost(ClassLessonsScreen(gateway: old.repository), 'en'));
    await tester.pumpAndSettle(); await chooseSection(tester, 'School 1 / 2026/2027 / A');
    expect(find.text('طالب 1'), findsOneWidget);
    await tester.pumpWidget(curriculumHost(ClassLessonsScreen(gateway: next.repository), 'en'));
    await tester.pumpAndSettle(); expect(find.text('طالب 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
