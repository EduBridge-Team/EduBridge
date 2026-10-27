import 'package:edubridge_app/screens/institution_statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';
import 'institution_statistics_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('statistics responsive refresh $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = InstitutionStatisticsFixture();
        await tester.pumpWidget(curriculumHost(InstitutionStatisticsScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('مدرسة الأمل'), 200, scrollable: find.byType(Scrollable).last);
        expect(find.text('مدرسة الأمل'), findsOneWidget);
        await resumeCurriculum(tester); expect(f.paths.where((p) => p.contains('management-report')), hasLength(2));
        f.status = 403; await resumeCurriculum(tester); expect(find.text('مدرسة الأمل'), findsNothing);
        f.status = 200; await resumeCurriculum(tester); expect(find.text('مدرسة الأمل'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('date filter and clear reach the scoped API', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final f = InstitutionStatisticsFixture();
    await tester.pumpWidget(curriculumHost(InstitutionStatisticsScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    final strings = MaterialLocalizations.of(tester.element(find.byType(InstitutionStatisticsScreen)));
    await tapCurriculum(tester, 'statistics-period');
    await tester.tap(find.byTooltip(strings.inputDateModeButtonLabel)); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '10/01/2026');
    await tester.enterText(find.byType(TextField).at(1), '10/26/2026');
    await tester.tap(find.text(strings.okButtonLabel)); await tester.pumpAndSettle();
    final report = f.paths.lastWhere((p) => p.contains('management-report'));
    expect(Uri.parse(report).queryParameters, {'from': '2026-10-01', 'to': '2026-10-26'});
    await tapCurriculum(tester, 'statistics-clear');
    expect(Uri.parse(f.paths.lastWhere((p) => p.contains('management-report'))).hasQuery, isFalse);
    expect(tester.takeException(), isNull);
  });
}
