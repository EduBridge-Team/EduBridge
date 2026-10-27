import 'package:edubridge_app/screens/institution_timetable/institution_teacher_absence_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';
import 'institution_timetable_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('absence and affected class $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionTimetableFixture(), repo = InstitutionTimetableFixture().repository;
        await tester.pumpWidget(curriculumHost(InstitutionTeacherAbsenceScreen(
          gateway: f.repository, timetableGateway: repo, initialDate: DateTime(2026, 10, 26)), language));
        await tester.pumpAndSettle();
        final field = find.descendant(of: find.byKey(const ValueKey('absence-teacher')), matching: find.byType(OutlinedButton));
        await tester.ensureVisible(field); await tester.tap(field); await tester.pumpAndSettle();
        await tester.tap(find.byType(SimpleDialogOption).first); await tester.pumpAndSettle();
        await tapCurriculum(tester, 'absence-submit');
        expect(f.absences, isEmpty);
        await tapCurriculum(tester, 'absence-confirm');
        expect(f.absences, hasLength(1)); expect(find.byKey(const ValueKey('absence-saved')), findsOneWidget);
        await tester.scrollUntilVisible(find.byKey(const ValueKey('timetable-substitute-80')), 200,
          scrollable: find.byType(Scrollable).last);
        await tapCurriculum(tester, 'timetable-substitute-80');
        expect(find.byKey(const ValueKey('substitute-date')), findsOneWidget);
        await resumeCurriculum(tester); expect(f.absences, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
