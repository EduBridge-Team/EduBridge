import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_school_record_screen.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';

import 'institution_academic_fixture.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('school record in $language at $width with large text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await http.runWithClient(
          () async {
            await tester.runAsync(() async {
              await tester.pumpWidget(
                MaterialApp(
                  locale: Locale(language),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
                  home: InstitutionSchoolRecordScreen(
                    academicGateway: InstitutionAcademicFixture().repository,
                    title: 'School',
                    organizationSlug: 'demo-institution',
                    schoolId: 5,
                  ),
                ),
              );
              await Future<void>.delayed(Duration.zero);
            });
            await tester.pumpAndSettle();
            expect(find.byType(BackButton), findsOneWidget);
            expect(
              find.text('Long school name for the authorized institution'),
              findsOneWidget,
            );
            expect(
              find.text('School name'),
              language == 'en' ? findsOneWidget : findsNothing,
            );
            final academic = find.byKey(
              const ValueKey('institution-open-academic'),
            );
            await tester.ensureVisible(academic);
            await tester.pumpAndSettle();
            await tester.tap(academic);
            await tester.pumpAndSettle();
            expect(find.byType(InstitutionAcademicScreen), findsOneWidget);
            await tester.tap(find.byType(BackButton));
            await tester.pumpAndSettle();
            expect(find.byType(InstitutionSchoolRecordScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
          () => MockClient((request) async {
            expect(
              request.url.path,
              '/api/institutions/demo-institution/schools/5',
            );
            return http.Response(
              jsonEncode({
                'school': {
                  'id': 5,
                  'name': 'Long school name for the authorized institution',
                  'slug': 'school-five',
                  'address': 'Gaza',
                  'phone': '123',
                  'email': 'school@example.test',
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
      });
    }
  }
}
