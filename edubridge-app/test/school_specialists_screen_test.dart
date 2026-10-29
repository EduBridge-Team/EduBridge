import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/institution_specialists/school_specialists_screen.dart';
import 'curriculum_ui_support.dart';
import 'school_specialists_fixture.dart';

Future<void> tapSpecialist(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  final scroll = find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target, 250, scrollable: scroll);
  await tester.ensureVisible(target); await tester.pumpAndSettle();
  await tester.tap(target); await tester.pumpAndSettle();
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('school-wide assign and end $language $width at 2x', (tester) async {
        tester.view.physicalSize = Size(width, 1800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = SchoolSpecialistsFixture();
        await tester.pumpWidget(curriculumHost(SchoolSpecialistsScreen(gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tapSpecialist(tester, 'specialist-add');
        await tester.tap(find.byKey(const ValueKey('specialist-option-7'))); await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('specialist-confirm'))); await tester.pumpAndSettle();
        expect(f.posts, hasLength(1));
        await tapSpecialist(tester, 'specialist-end-10');
        await tester.tap(find.byKey(const ValueKey('specialist-confirm'))); await tester.pumpAndSettle();
        expect(f.posts, hasLength(2));
        expect(find.byKey(const ValueKey('specialist-end-10')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('old specialist choice after resume cannot open a confirmation or write', (tester) async {
    final f = SchoolSpecialistsFixture();
    await tester.pumpWidget(curriculumHost(SchoolSpecialistsScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapSpecialist(tester, 'specialist-add');
    f.data['revision'] = 'r2'; await resumeCurriculum(tester);
    await tester.tap(find.byKey(const ValueKey('specialist-option-7'))); await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing); expect(f.posts, isEmpty);
  });
  testWidgets('old end confirmation after refresh is never submitted', (tester) async {
    final f = SchoolSpecialistsFixture();
    await tester.pumpWidget(curriculumHost(SchoolSpecialistsScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapSpecialist(tester, 'specialist-end-10');
    f.data['revision'] = 'r2'; await resumeCurriculum(tester);
    await tester.tap(find.byKey(const ValueKey('specialist-confirm'))); await tester.pumpAndSettle();
    expect(f.posts, isEmpty); expect(tester.takeException(), isNull);
  });
  testWidgets('server capabilities control actions; refresh denial clears history', (tester) async {
    final f = SchoolSpecialistsFixture();
    f.data['capabilities']['can_assign'] = false;
    (f.data['assignments'] as List).first['can_end'] = false;
    await tester.pumpWidget(curriculumHost(SchoolSpecialistsScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('specialist-add')), findsNothing);
    expect(find.byKey(const ValueKey('specialist-end-10')), findsNothing);
    f.status = 403; await resumeCurriculum(tester);
    expect(find.byKey(const ValueKey('specialist-assignment-10')), findsNothing);
    expect(f.posts, isEmpty);
  });
  testWidgets('replacing the school gateway invalidates an open confirmation', (tester) async {
    final f = SchoolSpecialistsFixture(), next = SchoolSpecialistsFixture()..status = 404;
    await tester.pumpWidget(curriculumHost(SchoolSpecialistsScreen(gateway: f.repository), 'en'));
    await tester.pumpAndSettle(); await tapSpecialist(tester, 'specialist-end-10');
    await tester.pumpWidget(curriculumHost(SchoolSpecialistsScreen(gateway: next.repository), 'en'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('specialist-confirm'))); await tester.pumpAndSettle();
    expect(f.posts, isEmpty); expect(next.posts, isEmpty);
    expect(find.byKey(const ValueKey('specialist-assignment-10')), findsNothing);
  });
}

