import 'package:edubridge_app/screens/institution_operations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'curriculum_ui_support.dart';
import 'institution_school_repository_test.dart' show response;

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
          'invalid school response shows error and recovers $language $width',
          (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var valid = false;
        await http.runWithClient(() async {
          await tester.runAsync(() async {
            await tester.pumpWidget(
                curriculumHost(const InstitutionOperationsScreen(), language));
            await Future<void>.delayed(Duration.zero);
          });
          await tester.pumpAndSettle();
          final emptyText = language == 'en'
              ? 'No schools are linked to this institution.'
              : 'لا توجد مدارس مرتبطة بالمؤسسة.';
          expect(find.text(emptyText), findsNothing);
          expect(find.textContaining('Missing school list'), findsOneWidget);
          expect(find.byIcon(Icons.add), findsNothing);
          expect(tester.takeException(), isNull);
          valid = true;
          await tester.runAsync(() async {
            await tester.tap(find.byIcon(Icons.refresh));
            await Future<void>.delayed(Duration.zero);
          });
          await tester.pumpAndSettle();
          expect(find.text(emptyText), findsOneWidget);
          expect(find.textContaining('Missing school list'), findsNothing);
          expect(find.byIcon(Icons.add), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
            () => MockClient((request) async {
                  if (request.url.path.endsWith('/my-organization')) {
                    return response({
                      'organization': {'id': 1, 'slug': 'demo-institution'}
                    });
                  }
                  if (request.url.path.endsWith('/management-report')) {
                    return response({
                      'summary': {'schools': 0},
                      'schools': []
                    });
                  }
                  return response(valid ? {'schools': []} : {});
                }));
      });
    }
  }
}
