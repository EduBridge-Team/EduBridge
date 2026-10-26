import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_attendance/institution_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_attendance_fixture.dart';

Future<void> attendanceChoice(WidgetTester tester, String key, int index) async {
  final field = find.byKey(ValueKey(key));
  final button = find.descendant(of: field, matching: find.byType(OutlinedButton)).first;
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  final choice = find.descendant(of: find.byType(SimpleDialog), matching: find.byType(SimpleDialogOption)).at(index);
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
}
Future<void> attendanceText(WidgetTester tester, String key, String text) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.enterText(target, text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('create, mark and close attendance $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionAttendanceFixture();
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(curriculumHost(InstitutionAttendanceScreen(gateway: f.repository,
          date: DateTime(2026, 10, 26)), language));
        await tester.pumpAndSettle();
        await tapCurriculum(tester, 'attendance-open-create');
        expect(find.text(strings.institutionAttendanceInitializeNotice), findsOneWidget);
        await attendanceChoice(tester, 'attendance-create-section', 0);
        await attendanceText(tester, 'attendance-create-period', '2');
        await attendanceText(tester, 'attendance-create-note', 'ملاحظة جديدة');
        await tapCurriculum(tester, 'attendance-create-save');
        expect(f.posts, hasLength(1));
        expect(f.posts.single['notes'], 'ملاحظة جديدة');
        expect(find.byKey(const ValueKey('attendance-child-9')), findsOneWidget);
        await tapCurriculum(tester, 'attendance-open-mark');
        await attendanceChoice(tester, 'attendance-mark-9', 1);
        await attendanceText(tester, 'attendance-note-9', 'غياب بعلم الأسرة');
        await tapCurriculum(tester, 'attendance-close');
        await tapCurriculum(tester, 'attendance-mark-save');
        expect(f.puts, isEmpty);
        await tapCurriculum(tester, 'attendance-confirm-close');
        expect(f.puts, hasLength(1));
        expect(f.puts.single['close_session'], isTrue);
        expect(find.text(strings.institutionAttendanceClosed), findsOneWidget);
        expect(find.byKey(const ValueKey('attendance-open-mark')), findsNothing);
        expect(find.text('غياب بعلم الأسرة'), findsOneWidget);
        await resumeCurriculum(tester);
        expect(f.posts, hasLength(1));
        expect(f.puts, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('cancel closing session never sends a PUT', (tester) async {
    final f = InstitutionAttendanceFixture();
    await tester.pumpWidget(curriculumHost(InstitutionAttendanceScreen(gateway: f.repository,
      sessionId: 60, date: DateTime(2026, 10, 26)), 'en'));
    await tester.pumpAndSettle();
    await tapCurriculum(tester, 'attendance-open-mark');
    await tapCurriculum(tester, 'attendance-close');
    await tapCurriculum(tester, 'attendance-mark-save');
    final cancel = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton));
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(f.puts, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
