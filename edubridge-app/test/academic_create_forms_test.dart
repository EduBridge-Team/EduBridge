import 'dart:async';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/screens/academics/academic_controller.dart';
import 'package:edubridge_app/screens/academics/academic_create_screen.dart';
import 'package:edubridge_app/screens/academics/academic_form_values.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_editor_test_support.dart';
import 'academic_filter_fixtures.dart';

void main() {
  for (final text in ['30', '٣٠', '۳۰', ' ٣0 ', '500', '٥٠٠']) {
    test('capacity parses keyboard numerals $text', () {
      expect(
        parseAcademicCapacity(text),
        text.contains('5') || text.contains('٥') ? 500 : 30,
      );
    });
  }
  for (final text in ['', '٣٠.٥', '3e1', '-٣', '+30', 'thirty']) {
    test('capacity rejects non-integer input $text', () {
      expect(parseAcademicCapacity(text), isNull);
    });
  }

  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      for (final kind in AcademicKind.values) {
        testWidgets(
          '${kind.name} editor validates and saves in $language at $width',
          (tester) async {
            final gateway = EditorAcademicGateway();
            final controller = AcademicController(gateway);
            addTearDown(controller.dispose);
            final strings = await AppLocalizations.delegate.load(
              Locale(language),
            );
            await openAcademicEditor(
              tester,
              controller,
              kind,
              language: language,
              width: width,
            );
            expect(find.byType(BrandAppBar), findsOneWidget);
            expect(find.byType(BackButton), findsOneWidget);
            await tapEditorKey(tester, 'academic-save');
            expect(gateway.writes, 0);
            expect(find.text(strings.academicRequired), findsWidgets);
            await tester.enterText(
              find.byKey(const ValueKey('academic-name')),
              '  New item  ',
            );
            if (kind == AcademicKind.year) {
              await tapEditorKey(tester, 'academic-save');
              expect(find.text(strings.academicDateInvalid), findsOneWidget);
              expect(gateway.writes, 0);
              await chooseEditorDate(
                tester,
                'academic-start',
                DateTime(2026, 9, 1),
              );
              await chooseEditorDate(
                tester,
                'academic-end',
                DateTime(2026, 8, 1),
              );
              await tapEditorKey(tester, 'academic-save');
              expect(gateway.writes, 0);
              await chooseEditorDate(
                tester,
                'academic-end',
                DateTime(2027, 6, 30),
              );
            }
            if (kind == AcademicKind.section) {
              await chooseEditorValue(tester, 'academic-year', currentYearName);
              await chooseEditorValue(tester, 'academic-grade', firstGradeName);
              await tester.enterText(
                find.byKey(const ValueKey('academic-capacity')),
                '٥٠١',
              );
              await tapEditorKey(tester, 'academic-save');
              expect(
                find.text(strings.academicCapacityInvalid),
                findsOneWidget,
              );
              expect(gateway.writes, 0);
              await tester.enterText(
                find.byKey(const ValueKey('academic-capacity')),
                '٣٠',
              );
            }
            await tapEditorKey(tester, 'academic-save');
            expect(gateway.writes, 1);
            expect(gateway.savedSchool, 10);
            expect(gateway.draft!.toJson()['name'], 'New item');
            if (kind == AcademicKind.section) {
              expect(gateway.draft!.yearId, 1);
              expect(gateway.draft!.gradeId, 2);
              expect(gateway.draft!.capacity, 30);
            }
            expect(find.byType(AcademicCreateScreen), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }

  testWidgets(
    'school switch blocks editor writes while preserving back navigation',
    (tester) async {
      final gateway = EditorAcademicGateway();
      final controller = AcademicController(gateway);
      addTearDown(controller.dispose);
      await openAcademicEditor(tester, controller, AcademicKind.grade);
      await tester.enterText(
        find.byKey(const ValueKey('academic-name')),
        'Grade',
      );
      gateway.data = filterCatalog(school: 11);
      await controller.reload();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('academic-save')))
            .onPressed,
        isNull,
      );
      expect(gateway.writes, 0);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AcademicCreateScreen), findsNothing);
    },
  );

  testWidgets('removed selection requires a valid replacement before saving', (
    tester,
  ) async {
    final gateway = EditorAcademicGateway();
    final controller = AcademicController(gateway);
    addTearDown(controller.dispose);
    await openAcademicEditor(tester, controller, AcademicKind.section);
    await tester.enterText(
      find.byKey(const ValueKey('academic-name')),
      'Section',
    );
    await chooseEditorValue(tester, 'academic-year', previousYearName);
    await chooseEditorValue(tester, 'academic-grade', firstGradeName);
    gateway.data = filterCatalog(removeYear: true);
    await controller.reload();
    await tester.pumpAndSettle();
    await tapEditorKey(tester, 'academic-save');
    expect(gateway.writes, 0);
    await chooseEditorValue(tester, 'academic-year', currentYearName);
    await tapEditorKey(tester, 'academic-save');
    expect(gateway.writes, 1);
    expect(gateway.draft!.yearId, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy save blocks back and duplicate submission', (tester) async {
    final gateway = EditorAcademicGateway()..pending = Completer<void>();
    final controller = AcademicController(gateway);
    addTearDown(controller.dispose);
    await openAcademicEditor(tester, controller, AcademicKind.grade);
    await tester.enterText(
      find.byKey(const ValueKey('academic-name')),
      'Grade',
    );
    final save = find.byKey(const ValueKey('academic-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(find.byType(AcademicCreateScreen), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(gateway.writes, 1);
    gateway.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AcademicCreateScreen), findsNothing);
  });
}
