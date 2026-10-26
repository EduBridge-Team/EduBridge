import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_timetable_fixture.dart';

Future<void> timetableChoice(WidgetTester tester, String key, int index) async {
  final button = find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(OutlinedButton)).first;
  await tester.ensureVisible(button); await tester.pumpAndSettle(); await tester.tap(button); await tester.pumpAndSettle();
  final choice = find.descendant(of: find.byType(SimpleDialog), matching: find.byType(SimpleDialogOption)).at(index);
  await tester.ensureVisible(choice); await tester.pumpAndSettle(); await tester.tap(choice); await tester.pumpAndSettle();
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('timetable filters and confirmed substitute $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionTimetableFixture();
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(curriculumHost(InstitutionAcademicScreen(organizationSlug: 'demo-institution', schoolId: 5,
          gateway: f.academic.repository, timetableGateway: f.repository), language));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byKey(const ValueKey('institution-open-timetable')), 200, scrollable: find.byType(Scrollable).last);
        await tapCurriculum(tester, 'institution-open-timetable');
        await timetableChoice(tester, 'timetable-year', 1);
        await timetableChoice(tester, 'timetable-section', 1);
        await timetableChoice(tester, 'timetable-day', 1);
        expect(find.text(strings.timetableEmpty), findsOneWidget);
        await timetableChoice(tester, 'timetable-day', 2);
        expect(find.byKey(const ValueKey('timetable-entry-80')), findsOneWidget);
        await tapCurriculum(tester, 'timetable-substitute-80');
        await timetableChoice(tester, 'substitute-teacher', 0);
        final note = find.byKey(const ValueKey('substitute-notes'));
        await tester.ensureVisible(note); await tester.pumpAndSettle();
        await tester.enterText(note, 'تكليف تجريبي');
        FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
        await tapCurriculum(tester, 'substitute-assign');
        await tapCurriculum(tester, 'substitute-cancel');
        expect(f.writes, isEmpty);
        await tapCurriculum(tester, 'substitute-assign');
        await tapCurriculum(tester, 'substitute-confirm');
        expect(f.writes, hasLength(1));
        expect(f.writes.single['substitute_teacher_id'], 8);
        expect(f.writes.single['notes'], 'تكليف تجريبي');
        expect(find.byKey(const ValueKey('substitute-saved')), findsOneWidget);
        f.status = 403;
        await resumeCurriculum(tester);
        expect(find.byKey(const ValueKey('substitute-teacher')), findsNothing);
        f.status = 200;
        await tester.tap(find.byIcon(Icons.refresh)); await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('substitute-teacher')), findsOneWidget);
        expect(f.writes, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
