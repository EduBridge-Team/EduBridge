import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/child_lessons/child_lessons_screen.dart';
import 'package:edubridge_app/screens/parent_lessons_screen.dart';
import 'package:edubridge_app/screens/parent_screen.dart';
import 'package:edubridge_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'userId': 1,
      'role': 'parent',
      'name': 'Parent',
    });
  });

  for (final language in ['ar', 'en']) {
    testWidgets('parent opens the selected child lessons without a student login ($language)',
        (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final requests = <String>[];

      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ParentScreen(),
          ));
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();

        final childLessonsButton =
            find.widgetWithText(OutlinedButton, strings.childLessonsFor('مريم'));
        expect(childLessonsButton, findsOneWidget);
        expect(find.byType(ParentScreen), findsOneWidget);

        await Scrollable.ensureVisible(
          tester.element(childLessonsButton),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(childLessonsButton.hitTestable());
          await tester.pump();
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();

        expect(find.byType(ChildLessonsScreen), findsOneWidget);
        final child = tester.widget<ChildLessonsScreen>(
          find.byType(ChildLessonsScreen),
        );
        expect(child.childId, 32);
        expect(child.childName, 'مريم');
        expect(find.byType(ParentLessonsScreen), findsNothing);
        expect(requests, contains('/children/32/lessons'));
        expect(requests, isNot(contains('/children/31/lessons')));
        expect(await ApiService.getRole(), 'parent');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((request) async {
        requests.add(request.url.path);
        if (request.url.path.endsWith('/children')) {
          return http.Response(jsonEncode({
            'children': [
              {'id': 31, 'name': 'نور', 'age': 8, 'status': 'assigned'},
              {'id': 32, 'name': 'مريم', 'age': 7, 'status': 'assigned'},
            ],
          }), 200);
        }
        if (request.url.path.endsWith('/children/32/lessons')) {
          return http.Response(jsonEncode({'lessons': [
            {'id': 8, 'title': 'درس مريم', 'content': 'محتوى الدرس'},
          ]}), 200);
        }
        if (request.url.path.endsWith('/progress/child/32')) {
          return http.Response(jsonEncode({'progress': []}), 200);
        }
        if (request.url.path.endsWith('/care-team')) {
          return http.Response(jsonEncode({'members': []}), 200);
        }
        return http.Response('{}', 200);
      }));
    });
  }
}
