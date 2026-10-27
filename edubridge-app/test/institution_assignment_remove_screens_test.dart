import 'package:edubridge_app/screens/institution_teacher_assignments/institution_teacher_assignments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';
import 'institution_teacher_assignments_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('cancel then confirm assignment removal $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionAssignmentsFixture()..addAssignment();
        await tester.pumpWidget(curriculumHost(InstitutionTeacherAssignmentsScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byKey(const ValueKey('institution-assignment-remove-100')), 200,
          scrollable: find.byType(Scrollable).last);
        await tapCurriculum(tester, 'institution-assignment-remove-100');
        expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('المعلم أحمد')), findsOneWidget);
        await tapCurriculum(tester, 'institution-assignment-remove-cancel'); expect(f.deletions, isEmpty);
        await tapCurriculum(tester, 'institution-assignment-remove-100');
        await tapCurriculum(tester, 'institution-assignment-remove-confirm');
        expect(f.deletions, hasLength(1)); expect(f.assignments, isEmpty);
        expect(find.byKey(const ValueKey('institution-assignment-100')), findsNothing);
        await resumeCurriculum(tester); expect(f.deletions, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
