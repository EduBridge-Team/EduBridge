import 'dart:async';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/academics/academic_screen.dart';
import 'package:edubridge_app/screens/curriculum/curriculum_create_screen.dart';
import 'package:edubridge_app/screens/curriculum/curriculum_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_filter_fixtures.dart';
import 'curriculum_http_fixture.dart';
import 'curriculum_ui_support.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      for (final term in [true, false]) {
        testWidgets(
          '${term ? 'term' : 'subject'} HTTP flow in $language at $width',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final fixture = CurriculumHttpFixture();
            final strings = await AppLocalizations.delegate.load(
              Locale(language),
            );
            await tester.pumpWidget(
              curriculumHost(
                CurriculumScreen(gateway: fixture.repository),
                language,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(BrandAppBar), findsOneWidget);
            expect(find.byType(BackButton), findsOneWidget);
            await tapCurriculum(
              tester,
              term ? 'curriculum-add-term' : 'curriculum-add-subject',
            );
            expect(find.byType(BrandAppBar), findsOneWidget);
            await tapCurriculum(tester, 'curriculum-save');
            expect(find.text(strings.academicRequired), findsWidgets);
            expect(fixture.writes, isEmpty);
            await tester.enterText(
              find.byKey(const ValueKey('curriculum-name')),
              term
                  ? ' Second term — الفصل الدراسي الثاني '
                  : ' Science — العلوم والأنشطة التعليمية الدامجة ',
            );
            if (term) {
              await chooseCurriculumYear(tester, curriculumYearName);
              await curriculumDate(
                tester,
                'curriculum-start',
                DateTime(2027, 1, 1),
              );
              await curriculumDate(
                tester,
                'curriculum-end',
                DateTime(2027, 6, 30),
              );
              await tapCurriculum(tester, 'curriculum-save');
              expect(fixture.writes, isEmpty); // Position 1 is already used.
              expect(find.text(strings.curriculumTermInvalid), findsOneWidget);
              await tester.enterText(
                find.byKey(const ValueKey('curriculum-position')),
                '٢',
              );
            } else {
              await tester.enterText(
                find.byKey(const ValueKey('curriculum-code')),
                ' SCI ',
              );
              await tapCurriculum(tester, 'curriculum-active');
            }
            await tapCurriculum(tester, 'curriculum-save');
            expect(find.byType(CurriculumCreateScreen), findsNothing);
            expect(fixture.writes.length, 1);
            expect(fixture.writes.single['expected_school_id'], 10);
            expect(
              fixture.writes.single['name'],
              (term
                  ? 'Second term — الفصل الدراسي الثاني'
                  : 'Science — العلوم والأنشطة التعليمية الدامجة'),
            );
            if (term) {
              expect(fixture.writes.single['academic_year_id'], 1);
              expect(fixture.writes.single['position'], 2);
              expect(
                find.byKey(const ValueKey('curriculum-term-5')),
                findsOneWidget,
              );
            } else {
              expect(fixture.writes.single['code'], 'SCI');
              expect(fixture.writes.single['is_active'], isFalse);
              expect(
                find.byKey(const ValueKey('curriculum-subject-9')),
                findsOneWidget,
              );
            }
            final reads = fixture.reads;
            await resumeCurriculum(tester);
            expect(fixture.reads, reads + 1);
            final scroll = find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first;
            tester.state<ScrollableState>(scroll).position.jumpTo(0);
            await tester.pump();
            await tester.drag(find.byType(ListView), const Offset(0, 350));
            await tester.pumpAndSettle();
            expect(fixture.reads, reads + 2);
            expect(fixture.writes.length, 1);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
  testWidgets(
    'academics opens curriculum without requiring the base catalog API',
    (tester) async {
      final fixture = CurriculumHttpFixture();
      final academic = FilterAcademicGateway()..failRead = true;
      await tester.pumpWidget(
        curriculumHost(
          AcademicScreen(
            gateway: academic,
            curriculumGateway: fixture.repository,
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await tapCurriculum(tester, 'open-school-curriculum');
      expect(find.byType(CurriculumScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('curriculum-term-4')), findsOneWidget);
      expect(fixture.reads, 1);
    },
  );
  testWidgets(
    'unavailable route shows recoverable error and no create actions',
    (tester) async {
      final fixture = CurriculumHttpFixture()..unavailable = true;
      await tester.pumpWidget(
        curriculumHost(CurriculumScreen(gateway: fixture.repository), 'ar'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('curriculum-add-term')), findsNothing);
      expect(
        find.byKey(const ValueKey('curriculum-add-subject')),
        findsNothing,
      );
      fixture.unavailable = false;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('curriculum-add-subject')),
        findsOneWidget,
      );
      expect(fixture.writes, isEmpty);
    },
  );
  testWidgets('busy save blocks back and duplicate submission', (tester) async {
    final fixture = CurriculumHttpFixture()..pending = Completer<void>();
    await tester.pumpWidget(
      curriculumHost(CurriculumScreen(gateway: fixture.repository), 'en'),
    );
    await tester.pumpAndSettle();
    await tapCurriculum(tester, 'curriculum-add-subject');
    await tester.enterText(
      find.byKey(const ValueKey('curriculum-name')),
      'Science',
    );
    final save = find.byKey(const ValueKey('curriculum-save'));
    await revealCurriculum(tester, save);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(find.byType(CurriculumCreateScreen), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(fixture.writes.length, 1);
    fixture.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CurriculumCreateScreen), findsNothing);
  });
  testWidgets('school change disables an open editor without blocking back', (
    tester,
  ) async {
    final fixture = CurriculumHttpFixture();
    await tester.pumpWidget(
      curriculumHost(CurriculumScreen(gateway: fixture.repository), 'en'),
    );
    await tester.pumpAndSettle();
    await tapCurriculum(tester, 'curriculum-add-subject');
    await tester.enterText(
      find.byKey(const ValueKey('curriculum-name')),
      'Science',
    );
    fixture.contextSchool = fixture.catalogSchool = 11;
    await resumeCurriculum(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('curriculum-save')))
          .onPressed,
      isNull,
    );
    expect(fixture.writes, isEmpty);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CurriculumCreateScreen), findsNothing);
  });
  testWidgets('empty academic years disable terms but allow subjects', (
    tester,
  ) async {
    final fixture = CurriculumHttpFixture()
      ..noYears = true
      ..terms = [];
    await tester.pumpWidget(
      curriculumHost(CurriculumScreen(gateway: fixture.repository), 'en'),
    );
    await tester.pumpAndSettle();
    final addTerm = find.byKey(const ValueKey('curriculum-add-term'));
    expect(tester.widget<OutlinedButton>(addTerm).onPressed, isNull);
    await tapCurriculum(tester, 'curriculum-add-subject');
    expect(find.byType(CurriculumCreateScreen), findsOneWidget);
    expect(fixture.writes, isEmpty);
  });
}
