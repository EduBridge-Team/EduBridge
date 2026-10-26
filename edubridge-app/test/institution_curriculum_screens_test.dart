import 'dart:convert';

import 'package:edubridge_app/screens/curriculum/curriculum_create_screen.dart';
import 'package:edubridge_app/screens/curriculum/curriculum_screen.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_curriculum_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'curriculum_ui_support.dart';
import 'institution_academic_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      for (final term in [true, false]) {
        testWidgets('institution curriculum $term $language $width', (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixture = InstitutionAcademicFixture();
          final writes = <String>[];
          final gateway = InstitutionCurriculumRepository(
            organizationSlug: 'demo-institution', organizationId: 4, schoolId: 5,
            client: EnrollmentApiClient(get: fixture.get, post: (path, body) async {
              writes.add(path);
              final item = {
                ...body, 'id': 100,
                if (term) 'academic_year_id': 10,
                if (!term) 'school_id': 5,
              };
              (fixture.data[term ? 'academic_terms' : 'subjects'] as List).add(item);
              return http.Response(jsonEncode({term ? 'term' : 'subject': item}), 201,
                headers: {'content-type': 'application/json; charset=utf-8'});
            }),
          );
          await tester.pumpWidget(curriculumHost(InstitutionAcademicScreen(
            organizationSlug: 'demo-institution', schoolId: 5,
            gateway: fixture.repository, curriculumGateway: gateway,
          ), language));
          await tester.pumpAndSettle();
          await tapCurriculum(tester, 'institution-open-curriculum');
          expect(find.byType(CurriculumScreen), findsOneWidget);
          await tapCurriculum(tester, term ? 'curriculum-add-term' : 'curriculum-add-subject');
          await tester.enterText(find.byKey(const ValueKey('curriculum-name')), ' سجل جديد ');
          if (term) {
            await chooseCurriculumYear(tester, '2026–2027');
            await curriculumDate(tester, 'curriculum-start', DateTime(2027, 2, 1));
            await curriculumDate(tester, 'curriculum-end', DateTime(2027, 6, 30));
            await tester.enterText(find.byKey(const ValueKey('curriculum-position')), '٢');
          }
          await tapCurriculum(tester, 'curriculum-save');
          expect(find.byType(CurriculumCreateScreen), findsNothing);
          expect(writes, hasLength(1));
          expect(writes.single, endsWith(term ? '/years/10/terms' : '/subjects'));
          expect(find.text('سجل جديد'), findsOneWidget);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect(find.byType(CurriculumScreen), findsNothing);
          expect(find.byType(InstitutionAcademicScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
