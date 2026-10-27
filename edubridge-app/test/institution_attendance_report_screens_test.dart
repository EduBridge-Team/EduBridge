import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_attendance/institution_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';
import 'institution_attendance_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('read-only attendance report $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionAttendanceFixture();
        await tester.pumpWidget(curriculumHost(InstitutionAttendanceScreen(gateway: f.repository), language));
        await tester.pumpAndSettle(); await tapCurriculum(tester, 'attendance-open-report');
        await tester.scrollUntilVisible(find.byKey(const ValueKey('attendance-report-student-9')), 200,
          scrollable: find.byType(Scrollable).last);
        expect(find.text('نور'), findsOneWidget); expect(find.textContaining('50.0%'), findsOneWidget);
        final field = find.descendant(of: find.byKey(const ValueKey('attendance-report-section')), matching: find.byType(OutlinedButton));
        await tester.ensureVisible(field); await tester.pumpAndSettle(); await tester.tap(field); await tester.pumpAndSettle();
        final option = find.byType(SimpleDialogOption).at(1);
        await tester.ensureVisible(option); await tester.tap(option); await tester.pumpAndSettle();
        expect(Uri.parse(f.paths.last).queryParameters['section_id'], '30');
        await tapCurriculum(tester, 'attendance-report-clear');
        expect(Uri.parse(f.paths.last).hasQuery, isFalse);
        await resumeCurriculum(tester);
        expect(f.posts, isEmpty); expect(f.puts, isEmpty); expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('failed refresh clears stale report and can recover', (tester) async {
    final f = InstitutionAttendanceFixture();
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(curriculumHost(InstitutionAttendanceScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapCurriculum(tester, 'attendance-open-report');
    f.status = 403; await resumeCurriculum(tester);
    expect(find.byKey(const ValueKey('attendance-report-student-9')), findsNothing);
    expect(find.text(l.attendanceReportEmpty), findsNothing);
    f.status = 200; f.report = {'summary': {'present': 0, 'absent': 0, 'late': 0, 'excused': 0}, 'students': []};
    await resumeCurriculum(tester); expect(find.text(l.attendanceReportEmpty), findsOneWidget);
  });
}
