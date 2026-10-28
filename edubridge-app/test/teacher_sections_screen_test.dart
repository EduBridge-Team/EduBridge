import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubridge_app/screens/teacher/teacher_screen.dart';
import 'package:edubridge_app/screens/teacher_sections/teacher_sections_tab.dart';
import 'package:edubridge_app/screens/teacher_sections/teacher_section_students_screen.dart';
import 'teacher_sections_fixture.dart';
import 'curriculum_ui_support.dart';

Widget students(List<Map<String, dynamic>> children, Future<void> Function() reload) => ListView(children: [for (final c in children) Text(c['name'] as String)]);
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('teacher home shows sections then only selected roster $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        FlutterSecureStorage.setMockInitialValues({}); SharedPreferences.setMockInitialValues({'userId': 9, 'role': 'teacher'});
        final f = TeacherSectionsFixture();
        await http.runWithClient(() async {
          await tester.runAsync(() async {
            await tester.pumpWidget(curriculumHost(TeacherScreen(sectionsGateway: f.repository), language));
            await Future<void>.delayed(Duration.zero);
          });
          await tester.pumpAndSettle();
          expect(find.text('شعبة 1'), findsOneWidget); expect(find.text('طالب قديم'), findsNothing);
          await tester.tap(find.byKey(const ValueKey('teacher-section-1'))); await tester.pumpAndSettle();
          expect(find.text('طالب 1'), findsOneWidget); expect(find.text('طالب 2'), findsNothing);
          final search = find.byKey(const ValueKey('teacher-section-students-search'));
          await tester.enterText(search, 'زميل'); await tester.pumpAndSettle();
          expect(find.text('طالب 1'), findsNothing); expect(find.text('زميل 1'), findsOneWidget);
          await tester.enterText(search, ''); await tester.pumpAndSettle();
          // Actual management cards keep full action labels at large text.
          expect(find.byType(FilledButton), findsWidgets); expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }, () => MockClient((request) async => http.Response(jsonEncode(request.url.path.endsWith('/me/verification')
          ? {'verification': {'verification_status': 'approved'}} : request.url.path.endsWith('/me')
          ? {'user': {'id': 9, 'name': 'معلم'}} : {'children': [{'id': 999, 'name': 'طالب قديم'}], 'lessons': [], 'disability_types': []}),
          200, headers: {'content-type': 'application/json; charset=utf-8'})));
      });
    }
  }
  testWidgets('section search and refreshed catalog remove old cards', (tester) async {
    final f = TeacherSectionsFixture();
    await tester.pumpWidget(curriculumHost(Scaffold(body: TeacherSectionsTab(gateway: f.repository, studentListBuilder: students)), 'en'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('teacher-sections-search')), 'شعبة 2'); await tester.pumpAndSettle();
    expect(find.text('شعبة 1'), findsNothing); expect(find.text('شعبة 2'), findsOneWidget);
    f.sectionStatus = 403; await resumeCurriculum(tester);
    expect(find.text('شعبة 2'), findsNothing);
  });
  testWidgets('roster denial and source replacement clear old students', (tester) async {
    final f = TeacherSectionsFixture(), next = TeacherSectionsFixture()..rosterStatus = 404;
    final gateway = f.repository, section = (await gateway.sections()).sections.first;
    await tester.pumpWidget(curriculumHost(TeacherSectionStudentsScreen(section: section, gateway: gateway, studentListBuilder: students), 'en'));
    await tester.pumpAndSettle(); expect(find.text('طالب 1'), findsOneWidget);
    f.rosterStatus = 403; await resumeCurriculum(tester); expect(find.text('طالب 1'), findsNothing);
    await tester.pumpWidget(curriculumHost(TeacherSectionStudentsScreen(section: section, gateway: next.repository, studentListBuilder: students), 'en'));
    await tester.pumpAndSettle(); expect(find.text('طالب 1'), findsNothing); expect(tester.takeException(), isNull);
  });
}
