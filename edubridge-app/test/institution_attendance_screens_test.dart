import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';
import 'package:edubridge_app/screens/institution_attendance/institution_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_attendance_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('institution attendance and detail $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionAttendanceFixture();
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(curriculumHost(InstitutionAcademicScreen(
          organizationSlug: 'demo-institution', schoolId: 5,
          gateway: f.academic.repository, attendanceGateway: f.repository), language));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byKey(const ValueKey('institution-open-attendance')), 180,
          scrollable: find.byType(Scrollable).last);
        await tapCurriculum(tester, 'institution-open-attendance');
        expect(find.byType(InstitutionAttendanceScreen), findsOneWidget);
        await tapCurriculum(tester, 'attendance-session-60');
        expect(find.text('نور'), findsOneWidget);
        expect(find.text(strings.institutionAttendancePresent), findsOneWidget);
        await tester.scrollUntilVisible(find.text('أحمد'), 180, scrollable: find.byType(Scrollable).last);
        expect(find.text(strings.institutionAttendanceAbsent), findsOneWidget);
        expect(find.text('عذر مكتوب'), findsOneWidget);
        f.status = 403;
        await resumeCurriculum(tester);
        expect(find.text('نور'), findsNothing);
        f.status = 200;
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('attendance-child-9')), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tapCurriculum(tester, 'attendance-date');
        Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(DateTime(2026, 10, 25));
        await tester.pumpAndSettle();
        expect(find.text(strings.institutionAttendanceEmpty), findsOneWidget);
        await tapCurriculum(tester, 'attendance-clear-date');
        expect(find.byKey(const ValueKey('attendance-session-60')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
