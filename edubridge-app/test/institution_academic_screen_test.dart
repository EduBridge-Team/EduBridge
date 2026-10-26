import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart' show curriculumHost, resumeCurriculum;
import 'institution_academic_fixture.dart';

Future<void> openAcademicGroup(WidgetTester tester, String group) async {
  final tile = find.byKey(ValueKey('institution-academic-$group'));
  await Scrollable.ensureVisible(tester.element(tile), alignment: 0.1);
  await tester.pumpAndSettle();
  final title = find
      .descendant(of: tile, matching: find.byType(ListTile))
      .first;
  await tester.tap(title);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('institution actual academic API at $width in $language', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = InstitutionAcademicFixture();
        final strings = await AppLocalizations.delegate.load(Locale(language));
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
        expect(find.byType(BrandAppBar), findsOneWidget);
        for (final group in [
          'years',
          'grades',
          'sections',
          'terms',
          'subjects',
        ]) {
          await openAcademicGroup(tester, group);
        }
        expect(find.text('مدرسة الأمل — Hope'), findsOneWidget);
        expect(find.text('شعبة الأمل'), findsOneWidget);
        expect(
          find.text('${strings.academicYears}: 2026–2027'),
          findsNWidgets(2),
        );
        expect(
          find.text('${strings.academicGrades}: الصف الثاني'),
          findsOneWidget,
        );
        expect(
          find.text('${strings.institutionAcademicTeacher}: المعلم محمود'),
          findsOneWidget,
        );
        expect(find.text('${strings.academicCapacity}: 0'), findsNothing);
        expect(find.text('الفصل الأول'), findsOneWidget);
        expect(find.text('اللغة العربية'), findsOneWidget);
        expect(find.text(strings.curriculumActive), findsOneWidget);
        fixture.status = 403;
        await resumeCurriculum(tester);
        expect(find.text(strings.institutionAcademicForbidden), findsOneWidget);
        expect(find.text('شعبة الأمل'), findsNothing);
        fixture.status = 200;
        fixture.data = {
          ...institutionAcademicJson(),
          'academic_years': [],
          'grades': [],
          'sections': [],
          'academic_terms': [],
          'subjects': [],
        };
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        await openAcademicGroup(tester, 'years');
        expect(find.text(strings.academicEmpty), findsOneWidget);
        expect(fixture.paths.length, 6);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
