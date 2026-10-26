import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';
import 'package:edubridge_app/screens/institution_teacher_assignments/institution_teacher_assignments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_teacher_assignments_fixture.dart';

Future<void> chooseAssignment(WidgetTester tester, String key) async {
  final field = find.byKey(ValueKey('institution-assignment-$key'));
  final button = find.descendant(of: field, matching: find.byType(OutlinedButton));
  await revealCurriculum(tester, button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  final choice = find.descendant(of: find.byType(SimpleDialog), matching: find.byType(SimpleDialogOption)).first;
  await tester.ensureVisible(choice);
  await tester.tap(choice);
  await tester.pumpAndSettle();
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('institution teacher assignment $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = InstitutionAssignmentsFixture();
        await tester.pumpWidget(curriculumHost(InstitutionAcademicScreen(
          organizationSlug: 'demo-institution', schoolId: 5,
          gateway: fixture.academic.repository,
          teacherAssignmentsGateway: fixture.repository,
        ), language));
        await tester.pumpAndSettle();
        await tapCurriculum(tester, 'institution-open-teacher-assignments');
        expect(find.byType(InstitutionTeacherAssignmentsScreen), findsOneWidget);
        await tapCurriculum(tester, 'institution-assignment-save');
        expect(fixture.writes, isEmpty);
        for (final field in ['teacher', 'section', 'subject']) {
          await chooseAssignment(tester, field);
        }
        await tapCurriculum(tester, 'institution-assignment-save');
        expect(fixture.writes, hasLength(1));
        expect(find.text('المعلم أحمد'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(InstitutionTeacherAssignmentsScreen), findsNothing);
      });
    }
  }
}
