import 'dart:async';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/schools/teacher_assignments_catalog.dart';
import 'package:edubridge_app/screens/academics/academic_screen.dart';
import 'package:edubridge_app/screens/teacher_assignments/teacher_assignment_create_screen.dart';
import 'package:edubridge_app/screens/teacher_assignments/teacher_assignments_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_filter_fixtures.dart';
import 'curriculum_ui_support.dart'
    show curriculumHost, revealCurriculum, resumeCurriculum;
import 'teacher_assignments_http_fixture.dart';

Future<void> tapAssignment(
  WidgetTester tester,
  String key, {
  bool choice = false,
}) async {
  final field = find.byKey(ValueKey(key));
  final target = choice
      ? find.descendant(
          of: field,
          matching: find.byWidgetPredicate(
            (widget) => widget is OutlinedButton,
          ),
        )
      : field;
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await revealCurriculum(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> selectAssignment(
  WidgetTester tester,
  String key,
  String label,
) async {
  await tapAssignment(tester, key, choice: true);
  expect(find.text('Inactive teacher'), findsNothing);
  expect(find.text('Inactive subject'), findsNothing);
  final target = find.descendant(
    of: find.byType(SimpleDialog),
    matching: find.text(label),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
        'assignment HTTP create/remove/refresh in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixture = TeacherAssignmentsHttpFixture();
          final strings = await AppLocalizations.delegate.load(
            Locale(language),
          );
          final section = TeacherAssignmentsCatalog.fromJson(
            assignmentsPayload(),
          ).sectionLabel(3);
          await tester.pumpWidget(
            curriculumHost(
              TeacherAssignmentsScreen(gateway: fixture.repository),
              language,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(BrandAppBar), findsOneWidget);
          expect(find.byType(BackButton), findsOneWidget);
          await tapAssignment(tester, 'assignment-add');
          await tapAssignment(tester, 'assignment-save');
          expect(find.text(strings.academicRequired), findsWidgets);
          expect(fixture.writes, isEmpty);
          await selectAssignment(
            tester,
            'assignment-teacher',
            firstTeacherName,
          );
          await selectAssignment(tester, 'assignment-section', section);
          await selectAssignment(
            tester,
            'assignment-subject',
            assignedSubjectName,
          );
          await tapAssignment(tester, 'assignment-save');
          expect(
            fixture.writes,
            isEmpty,
          ); // Existing triple cannot be repeated.
          expect(find.text(strings.teacherAssignmentInvalid), findsOneWidget);
          await selectAssignment(
            tester,
            'assignment-teacher',
            secondTeacherName,
          );
          await tapAssignment(tester, 'assignment-save');
          expect(find.byType(TeacherAssignmentCreateScreen), findsNothing);
          expect(fixture.writes.single, {
            'path': '/school/teacher-assignments',
            'expected_school_id': 10,
            ...newTeacherAssignment.toJson(),
          });
          await tapAssignment(tester, 'assignment-remove-51');
          // The confirmation includes teacher, section, subject and removal scope.
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(
            find.textContaining(strings.teacherAssignmentRemoveNotice),
            findsOneWidget,
          );
          await tester.tap(find.text(strings.enrollmentCancelAction));
          await tester.pumpAndSettle();
          expect(fixture.writes.length, 1);
          await tapAssignment(tester, 'assignment-remove-51');
          await tapAssignment(tester, 'assignment-confirm-remove');
          expect(fixture.writes.last, {
            'path': '/school/teacher-assignments/51/remove',
            'expected_school_id': 10,
            'expected_version': 1,
          });
          expect(find.byKey(const ValueKey('assignment-51')), findsNothing);
          final reads = fixture.reads;
          await resumeCurriculum(tester);
          expect(fixture.reads, reads + 1);
          final scroll = find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first;
          tester.state<ScrollableState>(scroll).position.jumpTo(0);
          await tester.pump();
          await tester.drag(find.byType(ListView), const Offset(0, 350));
          await tester.pumpAndSettle();
          expect(fixture.reads, reads + 2);
          expect(fixture.writes.length, 2);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  testWidgets('academic management opens school assignments independently', (
    tester,
  ) async {
    final fixture = TeacherAssignmentsHttpFixture();
    await tester.pumpWidget(
      curriculumHost(
        AcademicScreen(
          gateway: FilterAcademicGateway()..failRead = true,
          teacherAssignmentsGateway: fixture.repository,
        ),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await tapAssignment(tester, 'open-school-teacher-assignments');
    expect(find.byType(TeacherAssignmentsScreen), findsOneWidget);
    expect(fixture.reads, 1);
  });
  testWidgets('unavailable API removes actions and allows recovery', (
    tester,
  ) async {
    final fixture = TeacherAssignmentsHttpFixture()..unavailable = true;
    await tester.pumpWidget(
      curriculumHost(
        TeacherAssignmentsScreen(gateway: fixture.repository),
        'ar',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('assignment-add')), findsNothing);
    fixture.unavailable = false;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('assignment-add')), findsOneWidget);
    expect(fixture.writes, isEmpty);
  });
  testWidgets('school switch disables open editor but preserves back', (
    tester,
  ) async {
    final fixture = TeacherAssignmentsHttpFixture();
    await tester.pumpWidget(
      curriculumHost(
        TeacherAssignmentsScreen(gateway: fixture.repository),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await tapAssignment(tester, 'assignment-add');
    fixture.school = fixture.contextSchool = 11;
    await resumeCurriculum(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('assignment-save')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(TeacherAssignmentCreateScreen), findsNothing);
    expect(fixture.writes, isEmpty);
  });
  testWidgets(
    'changed assignment while confirming cannot remove a newer version',
    (tester) async {
      final fixture = TeacherAssignmentsHttpFixture();
      await tester.pumpWidget(
        curriculumHost(
          TeacherAssignmentsScreen(gateway: fixture.repository),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await tapAssignment(tester, 'assignment-remove-50');
      fixture.records = [assignmentJson(version: 2)];
      await resumeCurriculum(tester);
      await tapAssignment(tester, 'assignment-confirm-remove');
      expect(fixture.writes, isEmpty);
      await tapAssignment(tester, 'assignment-remove-50');
      await tapAssignment(tester, 'assignment-confirm-remove');
      expect(fixture.writes.single['expected_version'], 2);
    },
  );
  testWidgets('busy creation blocks back and duplicate submission', (
    tester,
  ) async {
    final fixture = TeacherAssignmentsHttpFixture()
      ..pending = Completer<void>();
    final section = TeacherAssignmentsCatalog.fromJson(assignmentsPayload())
        .sectionLabel(3);
    await tester.pumpWidget(
      curriculumHost(
        TeacherAssignmentsScreen(gateway: fixture.repository),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await tapAssignment(tester, 'assignment-add');
    await selectAssignment(tester, 'assignment-teacher', secondTeacherName);
    await selectAssignment(tester, 'assignment-section', section);
    await selectAssignment(tester, 'assignment-subject', assignedSubjectName);
    final save = find.byKey(const ValueKey('assignment-save'));
    await revealCurriculum(tester, save);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(find.byType(TeacherAssignmentCreateScreen), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(fixture.writes.length, 1);
    fixture.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherAssignmentCreateScreen), findsNothing);
  });
}
