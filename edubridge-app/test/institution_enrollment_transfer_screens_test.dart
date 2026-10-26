import 'package:edubridge_app/screens/institution_enrollment/institution_enrollment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';
import 'institution_enrollment_history_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('transfer confirmation $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionHistoryFixture()..addTarget();
        await tester.pumpWidget(curriculumHost(InstitutionEnrollmentHistoryScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tapCurriculum(tester, 'institution-transfer-2');
        expect(f.writes, isEmpty);
        final confirm = find.byKey(const ValueKey('confirm-institution-transfer'));
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.ensureVisible(find.byKey(const ValueKey('transfer-target-31')));
        await tester.tap(find.byKey(const ValueKey('transfer-target-31')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(f.writes, hasLength(1));
        expect(find.byKey(const ValueKey('institution-enrollment-3')), findsOneWidget);
        expect(find.byKey(const ValueKey('institution-transfer-2')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
