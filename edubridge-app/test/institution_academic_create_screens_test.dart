import 'dart:async';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/screens/academics/academic_create_screen.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_editor_test_support.dart'
    show tapEditorKey, chooseEditorValue, chooseEditorDate;
import 'curriculum_ui_support.dart' show curriculumHost;
import 'institution_academic_write_fixture.dart';

Future<void> openInstitutionCreate(
  WidgetTester tester,
  InstitutionAcademicWriteFixture fixture,
  AcademicKind kind,
  String language,
) async {
  await tester.pumpWidget(
    curriculumHost(
      InstitutionAcademicScreen(
        organizationSlug: 'demo-institution',
        schoolId: 5,
        gateway: fixture.repository,
      ),
      language,
    ),
  );
  await tester.pumpAndSettle();
  await tapEditorKey(tester, 'institution-add-${kind.name}');
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      for (final kind in AcademicKind.values) {
        testWidgets('institution ${kind.name} create $language at $width', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixture = InstitutionAcademicWriteFixture();
          await openInstitutionCreate(tester, fixture, kind, language);
          expect(find.byType(AcademicCreateScreen), findsOneWidget);
          expect(find.byType(BrandAppBar), findsOneWidget);
          await tapEditorKey(tester, 'academic-save');
          expect(fixture.writes, isEmpty);
          await tester.enterText(
            find.byKey(const ValueKey('academic-name')),
            ' سجل جديد ',
          );
          if (kind == AcademicKind.year) {
            await chooseEditorDate(
              tester,
              'academic-start',
              DateTime(2027, 9, 1),
            );
            await chooseEditorDate(
              tester,
              'academic-end',
              DateTime(2028, 6, 30),
            );
          }
          if (kind == AcademicKind.section) {
            await chooseEditorValue(tester, 'academic-year', '2026–2027');
            await chooseEditorValue(tester, 'academic-grade', 'الصف الثاني');
            await tester.enterText(
              find.byKey(const ValueKey('academic-capacity')),
              '٣٠',
            );
          }
          await tapEditorKey(tester, 'academic-save');
          expect(find.byType(AcademicCreateScreen), findsNothing);
          expect(fixture.writes, hasLength(1));
          expect(fixture.writes.single.body['name'], 'سجل جديد');
          expect(
            find.byKey(const ValueKey('institution-academic-saved')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'validation failure retains form; busy save blocks back and duplicate writes',
    (tester) async {
      final fixture = InstitutionAcademicWriteFixture()..status = 422;
      await openInstitutionCreate(tester, fixture, AcademicKind.grade, 'en');
      await tester.enterText(
        find.byKey(const ValueKey('academic-name')),
        'اسم جديد',
      );
      await tapEditorKey(tester, 'academic-save');
      expect(find.byType(AcademicCreateScreen), findsOneWidget);
      expect(find.text('اسم جديد'), findsOneWidget);
      fixture.status = 201;
      fixture.pending = Completer<void>();
      final save = find.byKey(const ValueKey('academic-save'));
      await tester.tap(save);
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      expect(find.byType(AcademicCreateScreen), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      fixture.pending!.complete();
      await tester.pumpAndSettle();
      expect(fixture.writes, hasLength(2));
      expect(find.byType(AcademicCreateScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'confirmed save with failed refresh returns without replaying write',
    (tester) async {
      final fixture = InstitutionAcademicWriteFixture()..failRefresh = true;
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      await openInstitutionCreate(tester, fixture, AcademicKind.grade, 'en');
      await tester.enterText(
        find.byKey(const ValueKey('academic-name')),
        'اسم جديد',
      );
      await tapEditorKey(tester, 'academic-save');
      expect(find.byType(AcademicCreateScreen), findsNothing);
      expect(find.text(strings.enrollmentSaved), findsOneWidget);
      expect(find.text(strings.institutionAcademicFailed), findsOneWidget);
      fixture.failRefresh = false;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(fixture.writes, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
