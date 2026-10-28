import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/class_lessons/class_assignment_screen.dart';
import 'package:edubridge_app/screens/class_lessons/class_assignment_controller.dart';
import 'curriculum_ui_support.dart';
import 'class_assignment_fixture.dart';

Future<void> chooseAssignment(WidgetTester tester, String key, String name) async {
  final button = find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(OutlinedButton));
  await revealCurriculum(tester, button); await tester.tap(button); await tester.pumpAndSettle();
  final option = find.descendant(of: find.byType(SimpleDialog), matching: find.text(name));
  await tester.ensureVisible(option); await tester.tap(option); await tester.pumpAndSettle();
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('assignment independent goals and adaptations $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = ClassAssignmentFixture();
        await tester.pumpWidget(curriculumHost(ClassAssignmentScreen(section: f.section, gateway: f.repository), language));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(find.byKey(const ValueKey('class-assignment-submit'))).onPressed, isNull);
        await chooseAssignment(tester, 'class-assignment-lesson', 'الدرس الأصلي');
        await chooseAssignment(tester, 'class-assignment-goal-100', 'هدف الطالب 100');
        final adaptation = find.byKey(const ValueKey('class-assignment-adaptation-100'));
        await revealCurriculum(tester, adaptation); await tester.enterText(adaptation, 'وقت إضافي');
        await tapCurriculum(tester, 'class-assignment-submit');
        await tester.tap(find.byKey(const ValueKey('class-assignment-confirm'))); await tester.pumpAndSettle();
        expect(f.posts, 1);
        final students = f.body!['students'] as List;
        expect(students[0]['iep_goal']['goal_id'], 103); expect(students[0]['adaptation'], 'وقت إضافي');
        expect(students[1]['iep_goal'], isNull); expect(students[1]['adaptation'], '');
        expect(find.byKey(const ValueKey('class-assignment-done')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('resume invalidates confirmation and clears choices', (tester) async {
    final f = ClassAssignmentFixture();
    await tester.pumpWidget(curriculumHost(ClassAssignmentScreen(section: f.section, gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await chooseAssignment(tester, 'class-assignment-lesson', 'الدرس الأصلي');
    await tapCurriculum(tester, 'class-assignment-submit');
    await resumeCurriculum(tester);
    await tester.tap(find.byKey(const ValueKey('class-assignment-confirm'))); await tester.pumpAndSettle();
    expect(f.posts, 0);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('class-assignment-submit'))).onPressed, isNull);
  });
  testWidgets('source replacement drops form and never posts to old source', (tester) async {
    final old = ClassAssignmentFixture(), next = ClassAssignmentFixture()..status = 404;
    await tester.pumpWidget(curriculumHost(ClassAssignmentScreen(section: old.section, gateway: old.repository), 'en'));
    await tester.pumpAndSettle(); await chooseAssignment(tester, 'class-assignment-lesson', 'الدرس الأصلي');
    await tester.pumpWidget(curriculumHost(ClassAssignmentScreen(section: next.section, gateway: next.repository), 'en'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('class-assignment-submit')), findsNothing);
    expect(old.posts, 0); expect(next.posts, 0); expect(tester.takeException(), isNull);
  });
  test('refresh clears lesson, per-student goal/adaptation and old callbacks', () async {
    final f = ClassAssignmentFixture();
    final state = ClassAssignmentController(f.repository);
    await state.reload();
    final expected = state.options!, epoch = state.generation;
    state.chooseLesson(10, expected, epoch);
    state.chooseGoal(100, 103, expected, epoch);
    state.adapt(100, 'old adaptation', expected, epoch);
    expect(state.draft().payloadStudents.first['adaptation'], 'old adaptation');
    await state.reload();
    state.chooseLesson(10, expected, epoch);
    expect(state.lessonId, isNull); expect(state.goal(100), isNull);
    state.chooseLesson(10, state.options!, state.generation);
    expect(state.draft().payloadStudents.first['adaptation'], '');
    expect(f.posts, 0); state.dispose();
  });
  for (final mode in ['uncertain', 'conflict']) {
    test('controller locks $mode across refresh and rejects stale selection', () async {
      final f = ClassAssignmentFixture();
      final state = ClassAssignmentController(f.repository);
      await state.reload();
      final old = state.options!, epoch = state.generation;
      state.chooseLesson(10, old, epoch);
      final draft = state.draft();
      if (mode == 'uncertain') f.throwPost = true;
      if (mode == 'conflict') f.data['revision'] = 'r2';
      await state.submit(old, epoch, draft);
      expect(state.locked, isTrue); expect(state.assignmentId, isNull);
      await state.reload();
      state.chooseLesson(10, old, epoch);
      expect(state.lessonId, isNull); expect(state.canSubmit, isFalse);
      await state.submit(old, epoch, draft);
      expect(f.posts, mode == 'uncertain' ? 1 : 0); state.dispose();
    });
  }
}
