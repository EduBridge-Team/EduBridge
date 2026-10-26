import 'package:edubridge_app/screens/institution_enrollment/institution_enrollment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_enrollment_history_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('withdrawal cancel and confirm $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionHistoryFixture();
        await tester.pumpWidget(curriculumHost(InstitutionEnrollmentHistoryScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('institution-withdraw-1')), findsNothing);
        await tapCurriculum(tester, 'institution-withdraw-2');
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(f.patches, isEmpty);
        await tapCurriculum(tester, 'cancel-institution-withdrawal');
        expect(find.byType(AlertDialog), findsNothing);
        expect(f.patches, isEmpty);
        await tapCurriculum(tester, 'institution-withdraw-2');
        await tapCurriculum(tester, 'confirm-institution-withdrawal');
        expect(f.patches, [{'status': 'withdrawn'}]);
        expect(f.rows, hasLength(2));
        expect(find.byKey(const ValueKey('institution-enrollment-2')), findsOneWidget);
        expect(find.byKey(const ValueKey('institution-withdraw-2')), findsNothing);
        await resumeCurriculum(tester);
        expect(f.patches, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('withdrawal conflict hides stale controls until refresh', (tester) async {
    final f = InstitutionHistoryFixture()..patchStatus = 409;
    await tester.pumpWidget(curriculumHost(InstitutionEnrollmentHistoryScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    await tapCurriculum(tester, 'institution-withdraw-2');
    await tapCurriculum(tester, 'confirm-institution-withdrawal');
    expect(find.byKey(const ValueKey('institution-withdraw-2')), findsNothing);
    expect(f.patches, hasLength(1));
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('institution-withdraw-2')), findsOneWidget);
    expect(f.patches, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
