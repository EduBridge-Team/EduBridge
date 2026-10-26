import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';
import 'package:edubridge_app/screens/institution_enrollment/institution_enrollment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_enrollment_history_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('institution enrollment history $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = InstitutionHistoryFixture();
        await tester.pumpWidget(curriculumHost(InstitutionAcademicScreen(
          organizationSlug: 'demo-institution', schoolId: 5,
          gateway: fixture.academic.repository, enrollmentHistoryGateway: fixture.repository,
        ), language));
        await tester.pumpAndSettle();
        await tapCurriculum(tester, 'institution-open-enrollment-history');
        expect(find.byType(InstitutionEnrollmentHistoryScreen), findsOneWidget);
        expect(find.text('نور'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('أحمد'), 200, scrollable: find.byType(Scrollable).last);
        expect(find.text('أحمد'), findsOneWidget);
        fixture.status = 403;
        await resumeCurriculum(tester);
        expect(find.text('نور'), findsNothing);
        fixture.status = 200;
        fixture.rows.clear();
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('institution-enrollment-2')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(InstitutionEnrollmentHistoryScreen), findsNothing);
      });
    }
  }
}
