import 'package:edubridge_app/screens/institution_statistics_screen.dart';
import 'package:edubridge_app/screens/institution_statistics/institution_period_statistics.dart';
import 'package:edubridge_app/screens/institution_statistics/institution_statistics_content.dart';
import 'package:edubridge_app/model/institutions/institution_statistics.dart';
import 'package:edubridge_app/screens/institution_statistics/institution_period_dialog.dart';
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
        await tapCurriculum(tester, 'statistics-period');
        expect(find.byType(InstitutionPeriodDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(InstitutionPeriodDialog))).pop();
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
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('prepared period counters $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1600); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(curriculumHost(const Scaffold(body: SingleChildScrollView(
          child: InstitutionPeriodStatistics(values: {'schools_created': 0, 'teachers_joined': 3}))), language));
        await tester.pumpAndSettle();
        final schools = find.byKey(const ValueKey('statistics-period-schools_created'));
        expect(find.descendant(of: schools, matching: find.text('0')), findsOneWidget);
        expect(find.text('Current totals'), findsNothing);
        expect(find.text('الإجماليات الحالية'), findsNothing);
        final students = find.byKey(const ValueKey('statistics-period-student_files_created'));
        expect(find.descendant(of: students, matching: find.text('—')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('attendance rate requires complete records and a nonzero denominator', (tester) async {
    final fixture = InstitutionStatisticsFixture();
    Future<void> render() async {
      final data = InstitutionStatistics.fromJson(4, 'demo-institution', fixture.data);
      await tester.pumpWidget(curriculumHost(Scaffold(body: SingleChildScrollView(
        child: InstitutionStatisticsContent(data: data, hasPeriod: true))), 'en'));
      await tester.pumpAndSettle();
    }
    await render();
    expect(find.text('70.0%'), findsOneWidget);
    final school = (fixture.data['schools'] as List).single as Map;
    (school['attendance'] as Map).remove('absent');
    await render();
    expect(find.text('70.0%'), findsNothing);
    expect(find.text('0.0%'), findsNothing);
    school['attendance'] = {'present': 0, 'absent': 0, 'late': 0, 'excused': 0};
    await render();
    expect(find.text('0.0%'), findsNothing);
    expect(find.text('—'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('date filter and clear reach the scoped API', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final f = InstitutionStatisticsFixture();
    await tester.pumpWidget(curriculumHost(InstitutionStatisticsScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    await tapCurriculum(tester, 'statistics-period');
    expect(find.byType(InstitutionPeriodDialog), findsOneWidget);
    final popup = tester.getRect(find.byKey(const ValueKey('statistics-period-popup')));
    expect(popup.width, lessThan(1280));
    expect(popup.center.dx, closeTo(640, 1));
    expect(popup.center.dy, closeTo(800, 1));
    tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker)).onDateChanged(DateTime(2026, 10, 1));
    await tester.pumpAndSettle();
    tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker)).onDateChanged(DateTime(2026, 10, 26));
    await tester.pumpAndSettle();
    await tapCurriculum(tester, 'statistics-period-apply');
    final report = f.paths.lastWhere((p) => p.contains('management-report'));
    expect(Uri.parse(report).queryParameters, {'from': '2026-10-01', 'to': '2026-10-26'});
    expect(find.text('Selected-period statistics'), findsOneWidget);
    expect(find.byKey(const ValueKey('statistics-period-schools_created')), findsOneWidget);
    expect(find.text('Current totals'), findsNothing);
    expect(find.text('Active teachers'), findsNothing);
    final specialist = find.byKey(const ValueKey('statistics-period-specialists_joined'));
    expect(find.descendant(of: specialist, matching: find.text('—')), findsOneWidget);
    await tapCurriculum(tester, 'statistics-clear');
    final now = DateTime.now();
    final reset = Uri.parse(f.paths.lastWhere((p) => p.contains('management-report'))).queryParameters;
    expect(reset['from'], '${now.year}-${now.month.toString().padLeft(2, '0')}-01');
    expect(reset['to'], '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    expect(tester.takeException(), isNull);
  });
}
