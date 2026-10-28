import 'dart:async';

import 'package:edubridge_app/model/schools/teacher_assignments_catalog.dart';
import 'package:edubridge_app/screens/teacher_assignments/teacher_assignment_create_screen.dart';
import 'package:edubridge_app/screens/teacher_assignments/teacher_assignments_controller.dart';
import 'package:edubridge_app/screens/teacher_assignments/teacher_assignments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'teacher_assignments_http_fixture.dart';
import 'teacher_assignments_screens_test.dart' show tapAssignment, selectAssignment;

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      void viewport(WidgetTester tester) {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      testWidgets('unchanged assignment confirmation expires after refresh $language $width', (tester) async {
        viewport(tester);
        final f = TeacherAssignmentsHttpFixture();
        await tester.pumpWidget(curriculumHost(TeacherAssignmentsScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tapAssignment(tester, 'assignment-remove-50');
        await resumeCurriculum(tester);
        await tapAssignment(tester, 'assignment-confirm-remove');
        expect(f.writes, isEmpty);
        expect(find.byKey(const ValueKey('assignment-50')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('school assignment gateway replacement reloads directory $language $width', (tester) async {
        viewport(tester);
        final first = TeacherAssignmentsHttpFixture(), next = TeacherAssignmentsHttpFixture()..records = [];
        await tester.pumpWidget(curriculumHost(TeacherAssignmentsScreen(gateway: first.repository), language));
        await tester.pumpAndSettle();
        await tapAssignment(tester, 'assignment-remove-50');
        await tester.pumpWidget(curriculumHost(TeacherAssignmentsScreen(gateway: next.repository), language));
        await tester.pumpAndSettle();
        await tapAssignment(tester, 'assignment-confirm-remove');
        expect(find.byKey(const ValueKey('assignment-50')), findsNothing);
        expect(next.reads, 1);
        expect(first.writes, isEmpty);
        expect(next.writes, isEmpty);
        expect(tester.takeException(), isNull);
      });
      testWidgets('replacement editor ignores pending choice and resets draft $language $width', (tester) async {
        viewport(tester);
        final first = TeacherAssignmentsController(TeacherAssignmentsHttpFixture().repository);
        final next = TeacherAssignmentsController(TeacherAssignmentsHttpFixture().repository);
        addTearDown(first.dispose);
        addTearDown(next.dispose);
        await first.reload();
        await next.reload();
        await tester.pumpWidget(curriculumHost(TeacherAssignmentCreateScreen(controller: first), language));
        await tester.pumpAndSettle();
        await selectAssignment(tester, 'assignment-teacher', secondTeacherName);
        await tapAssignment(tester, 'assignment-subject', choice: true);
        await tester.pumpWidget(curriculumHost(TeacherAssignmentCreateScreen(controller: next), language));
        await tester.pumpAndSettle();
        final option = find.descendant(of: find.byType(SimpleDialog), matching: find.text(assignedSubjectName));
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pumpAndSettle();
        for (final name in ['teacher', 'subject']) {
          expect(find.descendant(of: find.byKey(ValueKey('assignment-$name')),
            matching: find.byWidgetPredicate((widget) => widget is Text && (widget.data?.endsWith(': —') ?? false))), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('pending removal blocks back navigation', (tester) async {
    final f = TeacherAssignmentsHttpFixture()..pending = Completer<void>();
    final gateway = f.repository;
    await tester.pumpWidget(curriculumHost(Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TeacherAssignmentsScreen(gateway: gateway))), child: const Text('Open assignments')))), 'en'));
    await tester.tap(find.text('Open assignments'));
    await tester.pumpAndSettle();
    await tapAssignment(tester, 'assignment-remove-50');
    await tester.tap(find.byKey(const ValueKey('assignment-confirm-remove')));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    expect(find.byType(TeacherAssignmentsScreen), findsOneWidget);
    f.pending!.complete();
    await tester.pumpAndSettle();
    expect(f.writes, hasLength(1));
    expect(tester.takeException(), isNull);
  });
  testWidgets('old save completion cannot pop replacement editor', (tester) async {
    final f = TeacherAssignmentsHttpFixture()..pending = Completer<void>();
    final first = TeacherAssignmentsController(f.repository);
    final next = TeacherAssignmentsController(TeacherAssignmentsHttpFixture().repository);
    addTearDown(first.dispose);
    addTearDown(next.dispose);
    await first.reload();
    await next.reload();
    final current = ValueNotifier(first);
    addTearDown(current.dispose);
    await tester.pumpWidget(curriculumHost(Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
        ValueListenableBuilder<TeacherAssignmentsController>(valueListenable: current,
          builder: (context, controller, child) => TeacherAssignmentCreateScreen(controller: controller)))),
      child: const Text('Open editor')))), 'en'));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await selectAssignment(tester, 'assignment-teacher', secondTeacherName);
    await selectAssignment(tester, 'assignment-section', TeacherAssignmentsCatalog.fromJson(assignmentsPayload()).sectionLabel(3));
    await selectAssignment(tester, 'assignment-subject', assignedSubjectName);
    final save = find.byKey(const ValueKey('assignment-save'));
    await revealCurriculum(tester, save);
    await tester.tap(save);
    await tester.pump();
    current.value = next;
    await tester.pumpAndSettle();
    f.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherAssignmentCreateScreen), findsOneWidget);
    expect(f.writes, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
