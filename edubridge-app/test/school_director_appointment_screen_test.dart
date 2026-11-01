import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/screens/school_directors/school_director_appointment_screen.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/school_director_appointment_repository.dart';
import 'package:edubridge_app/theme.dart';

import 'curriculum_ui_support.dart';

class _Gateway implements SchoolDirectorAppointmentGateway {
  int writes = 0;
  bool uncertain = false;
  bool missingReadback = false;
  PersonalSchoolDirector? director;
  @override
  Future<List<DirectorSchool>> schools() async => const [
        DirectorSchool(
          id: 5,
          name: 'School A',
          organizationId: 2,
          organizationSlug: 'org',
        ),
      ];
  @override
  Future<PersonalSchoolDirector?> current(DirectorSchool school) async =>
      director;
  @override
  Future<int> appoint(DirectorSchool school, String email) async {
    writes++;
    if (uncertain) throw const DirectorApiException(DirectorFailure.uncertain);
    if (!missingReadback)
      director = PersonalSchoolDirector(8, 'Personal Director', email);
    return 8;
  }
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('personal appointment $language width $width large text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gateway = _Gateway();
        await tester.pumpWidget(
          curriculumHost(
            SchoolDirectorAppointmentScreen(gateway: gateway),
            language,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BrandAppBar), findsOneWidget);
        await tester.ensureVisible(find.byType(TextFormField));
        await tester.enterText(
          find.byType(TextFormField),
          'person@example.org',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(gateway.writes, 0);
        final confirm = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(gateway.writes, 1);
        expect(find.textContaining('Personal Director'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final missingReadback in [false, true]) {
    testWidgets(
        'uncertain appointment requires reload before another write $missingReadback',
        (
      tester,
    ) async {
      final gateway = _Gateway()
        ..uncertain = !missingReadback
        ..missingReadback = missingReadback;
      await tester.pumpWidget(
        curriculumHost(SchoolDirectorAppointmentScreen(gateway: gateway), 'en'),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'person@example.org');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(gateway.writes, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
