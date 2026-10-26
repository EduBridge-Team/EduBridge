import 'package:edubridge_app/model/institutions/institution_academic_records.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_section_filters_test.dart' show host, reveal;
import 'institution_academic_fixture.dart';
import 'institution_academic_screen_test.dart' show openAcademicGroup;

InstitutionAcademicRecords records({bool removeGrade = false, int school = 5}) {
  final data = institutionAcademicJson();
  (data['school'] as Map)['id'] = school;
  for (final key in ['academic_years', 'grades', 'subjects']) {
    for (final item in data[key] as List) {
      (item as Map)['school_id'] = school;
    }
  }
  if (!removeGrade) {
    (data['grades'] as List).add({'id': 21, 'school_id': school, 'name': 'Grade 3'});
    (data['sections'] as List).add({
      'id': 31, 'academic_year_id': 10, 'grade_id': 21,
      'name': 'Section B', 'capacity': 30,
    });
  }
  return InstitutionAcademicRecords.fromJson('demo-institution', 4, school, data);
}

Future<void> chooseFilter(WidgetTester tester, String key, String name) async {
  final button = find.byKey(ValueKey(key));
  await reveal(tester, button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  final option = find.descendant(of: find.byType(SimpleDialog), matching: find.text(name));
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('institution section filtering $language at $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Widget panel(InstitutionAcademicRecords data) => host(
          Scaffold(body: ListView(children: [InstitutionAcademicContent(records: data)])), language,
        );
        await tester.pumpWidget(panel(records()));
        await tester.pumpAndSettle();
        await openAcademicGroup(tester, 'sections');
        expect(find.text('Section B'), findsOneWidget);
        await chooseFilter(tester, 'institution-section-grade-filter', 'Grade 3');
        expect(find.text('Section B'), findsOneWidget);
        expect(find.text('شعبة الأمل'), findsNothing);
        await chooseFilter(tester, 'institution-section-year-filter', '2026–2027');
        expect(find.text('Section B'), findsOneWidget);
        // A fresh snapshot retains valid choices.
        await tester.pumpWidget(panel(records()));
        await tester.pumpAndSettle();
        expect(find.text('شعبة الأمل'), findsNothing);
        // Removed parent choices reset rather than hiding valid sections.
        await tester.pumpWidget(panel(records(removeGrade: true)));
        await tester.pumpAndSettle();
        expect(find.text('شعبة الأمل'), findsOneWidget);
        await tester.pumpWidget(panel(records()));
        await tester.pumpAndSettle();
        await chooseFilter(tester, 'institution-section-grade-filter', 'Grade 3');
        // Reused IDs in another school must not retain the previous filter.
        await tester.pumpWidget(panel(records(school: 6)));
        await tester.pumpAndSettle();
        expect(find.text('شعبة الأمل'), findsOneWidget);
        expect(find.text('Section B'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
