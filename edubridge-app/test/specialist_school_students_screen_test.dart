import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/specialist_schools/specialist_schools_screen.dart';
import 'package:edubridge_app/screens/specialist_schools/specialist_school_students_screen.dart';
import 'curriculum_ui_support.dart';
import 'specialist_school_students_fixture.dart';

Future<void> tapSchoolStudent(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  final scroll = find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target, 250, scrollable: scroll);
  await tester.ensureVisible(target); await tester.pumpAndSettle();
  await tester.tap(target); await tester.pumpAndSettle();
}
void main() {
  testWidgets('resume ignores a pre-background roster response after access revocation', (tester) async {
    final f = SpecialistSchoolStudentsFixture(), directory = await f.repository.schools();
    final pending = Completer<void>(); f.pendingRoster = pending;
    await tester.pumpWidget(curriculumHost(SpecialistSchoolStudentsScreen(
      specialistId: 7, school: directory.schools.first, gateway: f.repository), 'en'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    f.status = 403;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(); pending.complete(); await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('specialist-school-student-20')), findsNothing);
    expect(f.posts, isEmpty); expect(tester.takeException(), isNull);
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('school roster explicit selection and search $language $width at 2x', (tester) async {
        tester.view.physicalSize = Size(width, 1800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = SpecialistSchoolStudentsFixture();
        await tester.pumpWidget(curriculumHost(SpecialistSchoolsScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tapSchoolStudent(tester, 'specialist-school-2');
        expect(find.byType(SpecialistSchoolStudentsScreen), findsOneWidget); expect(f.posts, isEmpty);
        await tester.enterText(find.byKey(const ValueKey('specialist-school-search')), 'زميل');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('specialist-school-student-20')), findsNothing);
        expect(find.byKey(const ValueKey('specialist-school-student-30')), findsNothing);
        await tester.enterText(find.byKey(const ValueKey('specialist-school-search')), '');
        await tester.pumpAndSettle();
        await tapSchoolStudent(tester, 'specialist-follow-20');
        await tester.tap(find.byKey(const ValueKey('specialist-follow-confirm'))); await tester.pumpAndSettle();
        expect(f.posts, hasLength(1));
        expect(find.byKey(const ValueKey('specialist-follow-20')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('confirmation is invalid after resume and transfer', (tester) async {
    final f = SpecialistSchoolStudentsFixture(), directory = await f.repository.schools();
    await tester.pumpWidget(curriculumHost(SpecialistSchoolStudentsScreen(
      specialistId: 7, school: directory.schools.first, gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapSchoolStudent(tester, 'specialist-follow-20');
    (f.rosters[2]!['students'] as List).removeAt(0); f.rosters[2]!['revision'] = 'r2';
    await resumeCurriculum(tester);
    await tester.tap(find.byKey(const ValueKey('specialist-follow-confirm'))); await tester.pumpAndSettle();
    expect(f.posts, isEmpty);
    expect(find.byKey(const ValueKey('specialist-school-student-20')), findsNothing);
  });
  testWidgets('school change cannot submit an old confirmation', (tester) async {
    final f = SpecialistSchoolStudentsFixture(), directory = await f.repository.schools();
    await tester.pumpWidget(curriculumHost(SpecialistSchoolStudentsScreen(
      specialistId: 7, school: directory.schools.first, gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapSchoolStudent(tester, 'specialist-follow-20');
    await tester.pumpWidget(curriculumHost(SpecialistSchoolStudentsScreen(
      specialistId: 7, school: directory.schools.last, gateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('specialist-follow-confirm'))); await tester.pumpAndSettle();
    expect(f.posts, isEmpty);
    expect(find.byKey(const ValueKey('specialist-school-student-20')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('revoked school access clears visible students and actions', (tester) async {
    final f = SpecialistSchoolStudentsFixture(), directory = await f.repository.schools();
    await tester.pumpWidget(curriculumHost(SpecialistSchoolStudentsScreen(
      specialistId: 7, school: directory.schools.first, gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); f.status = 403; await resumeCurriculum(tester);
    expect(find.byKey(const ValueKey('specialist-school-student-20')), findsNothing);
    expect(find.byKey(const ValueKey('specialist-follow-20')), findsNothing);
    expect(f.posts, isEmpty);
  });
}

