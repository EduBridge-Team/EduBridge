import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/enrollment/enrollment_models.dart';
import 'package:edubridge_app/screens/enrollment/parent_enrollment_screen.dart';
import 'package:edubridge_app/screens/enrollment/school_dashboard_screen.dart';
import 'curriculum_ui_support.dart';
import 'enrollment_fakes.dart';
import 'institution_timetable_fixture.dart';
import 'package:edubridge_app/screens/institution_timetable/institution_timetable_screen.dart';
import 'enrollment_screens_test.dart' show searchSchool;

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'role': 'school', 'name': 'Operator'});
    await SharedPreferences.getInstance();
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('child change clears search and late results $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final old = FakeParentEnrollment(), next = FakeParentEnrollment();
        final gate = Completer<List<EnrollmentSchool>>(); old.pendingSearch['School'] = gate;
        final scope = ValueNotifier(false); addTearDown(scope.dispose);
        await tester.pumpWidget(curriculumHost(ValueListenableBuilder<bool>(valueListenable: scope,
          builder: (_, changed, child) => ParentEnrollmentScreen(key: const ValueKey('same-parent-route'),
            childId: changed ? 7 : 6, childName: changed ? 'Other child' : 'Child A', gateway: changed ? next : old)), language));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('enrollment-school-query')), 'School');
        await tester.tap(find.byKey(const ValueKey('enrollment-school-search'))); await tester.pump();
        scope.value = true; await tester.pumpAndSettle();
        gate.complete([enrollmentSchool]); await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('enrollment-submit-10')), findsNothing);
        expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, isEmpty);
        expect(old.writes, 0); expect(next.writes, 0); expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('guardian confirmation is discarded after resume refresh', (tester) async {
    final f = FakeParentEnrollment(); final l = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(curriculumHost(ParentEnrollmentScreen(childId: 6, childName: 'Child A', gateway: f), 'en'));
    await tester.pumpAndSettle(); await searchSchool(tester);
    await tester.tap(find.byKey(const ValueKey('enrollment-submit-10'))); await tester.pumpAndSettle();
    await resumeCurriculum(tester);
    await tester.tap(find.text(l.enrollmentConfirm)); await tester.pumpAndSettle();
    expect(f.writes, 0);
  });
  testWidgets('school gateway change replaces displayed requests', (tester) async {
    final old = FakeSchoolEnrollment(), next = FakeSchoolEnrollment()..requests = [];
    final scope = ValueNotifier(false); addTearDown(scope.dispose);
    await tester.pumpWidget(curriculumHost(ValueListenableBuilder<bool>(valueListenable: scope,
      builder: (_, changed, child) => SchoolDashboardScreen(key: const ValueKey('same-school-route'), gateway: changed ? next : old)), 'en'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('enrollment-reject-50')), 200, scrollable: find.byType(Scrollable).last);
    expect(find.byKey(const ValueKey('enrollment-reject-50')), findsOneWidget);
    scope.value = true; await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('enrollment-reject-50')), findsNothing); expect(old.writes, 0); expect(next.writes, 0);
  });
  testWidgets('timetable confirmation is discarded after refresh', (tester) async {
    final f = InstitutionTimetableFixture();
    await tester.pumpWidget(curriculumHost(InstitutionTimetableScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('timetable-delete-80')), 200, scrollable: find.byType(Scrollable).last);
    await tapCurriculum(tester, 'timetable-delete-80'); await resumeCurriculum(tester);
    await tapCurriculum(tester, 'timetable-delete-confirm'); expect(f.deletions, isEmpty);
  });
  testWidgets('back cannot hide a pending timetable deletion', (tester) async {
    final f = InstitutionTimetableFixture(), gate = Completer<void>();
    f.beforeWrite = () => gate.future;
    await tester.pumpWidget(curriculumHost(Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InstitutionTimetableScreen(gateway: f.repository))),
      child: const Text('Open timetable')))), 'en'));
    await tester.tap(find.text('Open timetable')); await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('timetable-delete-80')), 200, scrollable: find.byType(Scrollable).last);
    await tapCurriculum(tester, 'timetable-delete-80');
    await tester.tap(find.byKey(const ValueKey('timetable-delete-confirm'))); await tester.pump();
    await tester.pageBack(); await tester.pump();
    expect(find.byType(InstitutionTimetableScreen), findsOneWidget);
    gate.complete(); await tester.pumpAndSettle(); expect(f.deletions, hasLength(1));
    expect(tester.takeException(), isNull);
  });

}
