import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/parent_screen.dart';
import 'package:edubridge_app/screens/child_lessons/child_lessons_screen.dart';
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
      'userId': 1, 'role': 'parent', 'name': 'Parent',
    });
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('parent lesson access stays inside the selected child profile in $locale', (tester) async {
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ParentScreen(),
          ));
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();
        final l10n = await AppLocalizations.delegate.load(Locale(locale));

        // Preserve the parent-lessons action already present on each child card.
        // The agreed change forbids adding a NEW lessons button, not removing old ones.
        expect(find.text(l10n.parentLessons), findsWidgets);
        expect(find.text('Child Six'), findsOneWidget);
        expect(find.text('Child Seven'), findsOneWidget);

        // The child ID, not a student login or a global lesson list, selects the lesson scope.
        await tester.tap(find.text('Child Six'));
        await tester.pump();
        final screen = tester.widget<ChildLessonsScreen>(find.byType(ChildLessonsScreen));
        expect(screen.childId, 6);
        expect(screen.childName, 'Child Six');
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((request) async {
        if (request.url.path.endsWith('/children')) {
          return http.Response(jsonEncode({
            'children': [
              {'id': 6, 'name': 'Child Six', 'age': 7, 'status': 'assigned'},
              {'id': 7, 'name': 'Child Seven', 'age': 8, 'status': 'assigned'},
            ],
          }), 200);
        }
        if (request.url.path.endsWith('/children/6/lessons')) {
          return http.Response(jsonEncode({'lessons': []}), 200);
        }
        if (request.url.path.endsWith('/progress/child/6')) {
          return http.Response(jsonEncode({'progress': []}), 200);
        }
        return http.Response('{}', 200);
      }));
    });
  }
}
