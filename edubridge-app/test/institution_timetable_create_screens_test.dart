import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_timetable/institution_timetable_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_timetable_fixture.dart';

Future<void> createTimetableChoice(WidgetTester tester, String key, int index) async {
  final button = find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(OutlinedButton)).first;
  await tester.ensureVisible(button); await tester.pumpAndSettle(); await tester.tap(button); await tester.pumpAndSettle();
  final choice = find.descendant(of: find.byType(SimpleDialog), matching: find.byType(SimpleDialogOption)).at(index);
  await tester.ensureVisible(choice); await tester.pumpAndSettle(); await tester.tap(choice); await tester.pumpAndSettle();
}
Future<void> createTimetableText(WidgetTester tester, String key, String value) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field); await tester.pumpAndSettle(); await tester.enterText(field, value);
  FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
}
Future<void> fillTimetable(WidgetTester tester, {String period = '2'}) async {
  await createTimetableChoice(tester, 'timetable-create-year', 0);
  await createTimetableChoice(tester, 'timetable-create-section', 0);
  await createTimetableChoice(tester, 'timetable-create-subject', 0);
  await createTimetableChoice(tester, 'timetable-create-teacher', 2);
  await createTimetableChoice(tester, 'timetable-create-day', 1);
  await createTimetableText(tester, 'timetable-create-period', period);
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('create school timetable $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionTimetableFixture();
        await tester.pumpWidget(curriculumHost(InstitutionTimetableScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tapCurriculum(tester, 'timetable-open-create');
        await tapCurriculum(tester, 'timetable-create-submit');
        expect(f.creations, isEmpty);
        await fillTimetable(tester);
        await createTimetableText(tester, 'timetable-create-start', '09:00');
        await createTimetableText(tester, 'timetable-create-end', '09:45');
        await createTimetableText(tester, 'timetable-create-room', 'غرفة جديدة');
        await tapCurriculum(tester, 'timetable-create-submit');
        expect(f.creations, hasLength(1));
        expect(f.creations.single['teacher_id'], 8);
        expect(f.creations.single['weekday'], 2);
        expect(f.creations.single['room'], 'غرفة جديدة');
        await tester.scrollUntilVisible(find.byKey(const ValueKey('timetable-entry-81')), 200, scrollable: find.byType(Scrollable).last);
        expect(find.text('المعلمة سارة'), findsOneWidget);
        expect(find.textContaining('09:00:00'), findsOneWidget);
        await resumeCurriculum(tester);
        expect(f.creations, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('conflict is visible and does not create a class', (tester) async {
    final f = InstitutionTimetableFixture();
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(curriculumHost(InstitutionTimetableScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapCurriculum(tester, 'timetable-open-create');
    await fillTimetable(tester, period: '1');
    await tapCurriculum(tester, 'timetable-create-submit');
    expect(f.creations, isEmpty);
    expect(find.text(strings.timetableCreateConflict), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
