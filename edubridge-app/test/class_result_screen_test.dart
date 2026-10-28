import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/class_lesson_results/class_result_screen.dart';
import 'package:edubridge_app/screens/class_lesson_results/class_result_controller.dart';
import 'package:edubridge_app/screens/class_lessons/class_lesson_results.dart';
import 'class_result_fixture.dart';
import 'curriculum_ui_support.dart';

Future<void> fillResult(WidgetTester tester, {bool measurement = true}) async {
  final state = find.descendant(of: find.byKey(const ValueKey('class-result-state')), matching: find.byType(OutlinedButton));
  await revealCurriculum(tester, state); await tester.tap(state); await tester.pumpAndSettle();
  final completed = find.descendant(of: find.byType(SimpleDialog), matching: find.byWidgetPredicate((w) => w is Text && ['مكتمل', 'Completed'].contains(w.data)));
  await tester.ensureVisible(completed); await tester.tap(completed); await tester.pumpAndSettle();
  await curriculumDate(tester, 'class-result-date', DateTime(2026, 10, 28));
  for (final field in {'score': '0', 'maximum': '10', if (measurement) 'measurement': '2', 'observation': 'دليل الأداء الأصلي'}.entries) {
    final input = find.byKey(ValueKey('class-result-${field.key}'));
    await revealCurriculum(tester, input); await tester.enterText(input, field.value); await tester.pump();
  }
}
void makeResultReady(ClassResultController state) {
  state.change(state.options!, state.generation, () {
    state.state = 'completed'; state.observedOn = DateTime(2026, 10, 28); state.observation = 'evidence';
  });
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('records independent result/evidence $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = ClassResultFixture();
        await tester.pumpWidget(curriculumHost(ClassResultScreen(source: f.source, gateway: f.repository), language));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(find.byKey(const ValueKey('class-result-submit'))).onPressed, isNull);
        await fillResult(tester);
        await tapCurriculum(tester, 'class-result-submit');
        await tester.tap(find.byKey(const ValueKey('class-result-confirm'))); await tester.pumpAndSettle();
        expect(f.posts, 1); expect(f.body!['score'], 0); expect(f.body!['goal_measurement']['value'], 2);
        expect(find.byKey(const ValueKey('class-result-done')), findsOneWidget); expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('old date dialog invalid after resume', (tester) async {
    final f = ClassResultFixture();
    await tester.pumpWidget(curriculumHost(ClassResultScreen(source: f.source, gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapCurriculum(tester, 'class-result-date');
    await resumeCurriculum(tester);
    Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(DateTime(2026, 10, 28));
    await tester.pumpAndSettle();
    expect(find.text('Observation date: —'), findsOneWidget); expect(f.posts, 0);
  });
  testWidgets('old confirmation invalid after resume', (tester) async {
    final f = ClassResultFixture();
    await tester.pumpWidget(curriculumHost(ClassResultScreen(source: f.source, gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await fillResult(tester); await tapCurriculum(tester, 'class-result-submit');
    await resumeCurriculum(tester);
    await tester.tap(find.byKey(const ValueKey('class-result-confirm'))); await tester.pumpAndSettle();
    expect(f.posts, 0);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('class-result-submit'))).onPressed, isNull);
    expect(tester.widget<EditableText>(find.descendant(of: find.byKey(const ValueKey('class-result-observation')), matching: find.byType(EditableText))).controller.text, '');
  });
  testWidgets('source replacement removes draft and unsupported API cannot save', (tester) async {
    final old = ClassResultFixture(), next = ClassResultFixture()..status = 404;
    await tester.pumpWidget(curriculumHost(ClassResultScreen(source: old.source, gateway: old.repository), 'en'));
    await tester.pumpAndSettle(); await fillResult(tester);
    await tester.pumpWidget(curriculumHost(ClassResultScreen(source: next.source, gateway: next.repository), 'en'));
    await tester.pumpAndSettle(); expect(find.byKey(const ValueKey('class-result-submit')), findsNothing);
    expect(old.posts, 0); expect(next.posts, 0); expect(tester.takeException(), isNull);
  });
  testWidgets('catalog action requires assignment identity and emits exact student', (tester) async {
    for (final hasAssignment in [false, true]) {
      final f = ClassResultFixture(assignment: hasAssignment);
      int? child;
      await tester.pumpWidget(curriculumHost(Scaffold(body: SingleChildScrollView(child: ClassLessonResults(
        section: f.source.section, onRecord: (lesson, student) { child = student.childId; expect(lesson.assignmentId, 77); }))), 'en'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(OutlinedButton, 'Record student result');
      if (hasAssignment) { await revealCurriculum(tester, button); await tester.tap(button); expect(child, 100); }
      else { expect(button, findsNothing); expect(child, isNull); }
    }
  });
  test('serialize writes and block refresh while recording', () async {
    final wait = Completer<void>(), f = ClassResultFixture();
    f.beforePost = () => wait.future;
    final state = ClassResultController(f.repository); await state.reload(); makeResultReady(state);
    final expected = state.options!, epoch = state.generation, draft = state.draft!;
    final first = state.submit(expected, epoch, draft);
    await Future<void>.delayed(Duration.zero);
    expect(state.busy, isTrue);
    await state.submit(expected, epoch, draft); await state.reload(); expect(state.generation, epoch);
    wait.complete(); await first; expect(f.posts, 1); expect(state.resultId, 88); state.dispose();
  });
  for (final mode in ['uncertain', 'conflict']) {
    test('lock $mode survives refresh and rejects old input callbacks', () async {
      final f = ClassResultFixture();
      final controller = ClassResultController(f.repository); await controller.reload(); makeResultReady(controller);
      final expected = controller.options!, epoch = controller.generation, draft = controller.draft!;
      if (mode == 'uncertain') f.lost = true;
      if (mode == 'conflict') f.data['revision'] = 'r2';
      await controller.submit(expected, epoch, draft); expect(controller.locked, isTrue);
      await controller.reload(); controller.change(expected, epoch, () => controller.observation = 'stale');
      expect(controller.observation, ''); expect(controller.canSubmit, isFalse);
      await controller.submit(expected, epoch, draft); expect(f.posts, mode == 'uncertain' ? 1 : 0); controller.dispose();
    });
  }
}
