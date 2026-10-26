import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_timetable/institution_timetable_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';
import 'institution_timetable_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('confirm or cancel removal $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionTimetableFixture();
        final l = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(curriculumHost(InstitutionTimetableScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byKey(const ValueKey('timetable-delete-80')), 200,
          scrollable: find.byType(Scrollable).last);
        await tapCurriculum(tester, 'timetable-delete-80');
        expect(find.text(l.timetableDeleteConfirm), findsOneWidget);
        await tester.tap(find.text(l.timetableDeleteCancel)); await tester.pumpAndSettle();
        expect(f.deletions, isEmpty);
        await tapCurriculum(tester, 'timetable-delete-80');
        await tapCurriculum(tester, 'timetable-delete-confirm');
        expect(f.deletions, hasLength(1)); expect(find.text(l.timetableEmpty), findsOneWidget);
        await resumeCurriculum(tester); expect(f.deletions, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
