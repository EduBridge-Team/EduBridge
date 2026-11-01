import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/educational_plan_sheet.dart';
import 'package:edubridge_app/services/api_service.dart';
import 'curriculum_ui_support.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'role': 'specialist', 'userId': 2});
    FlutterSecureStorage.setMockInitialValues({});
  });
  for (final language in ['ar', 'en']) {
    testWidgets('plan uses newest evaluation in server order $language',
        (tester) async {
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(curriculumHost(
              const Scaffold(
                  body:
                      EducationalPlanSheet(child: {'id': 7, 'name': 'Child'})),
              language));
          await Future<void>.delayed(Duration.zero);
          await tester.pump();
        });
        await tester.pumpAndSettle();
        expect(find.textContaining('NEWEST PLAN'), findsOneWidget);
        expect(find.textContaining('OUTDATED PLAN'), findsNothing);
      },
          () => MockClient((_) async => http.Response(
              jsonEncode({
                'evaluations': [
                  {'id': 2, 'child_id': 7, 'educational_plan': 'NEWEST PLAN'},
                  {'id': 1, 'child_id': 7, 'educational_plan': 'OUTDATED PLAN'},
                ]
              }),
              200)));
    });
    testWidgets('failed evaluation load is not an empty history $language',
        (tester) async {
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(curriculumHost(
              const Scaffold(
                  body:
                      EducationalPlanSheet(child: {'id': 7, 'name': 'Child'})),
              language));
          await Future<void>.delayed(Duration.zero);
          await tester.pump();
        });
        await tester.pumpAndSettle();
        final strings = await AppLocalizations.delegate.load(Locale(language));
        expect(find.text(strings.planEvaluationFailed), findsOneWidget);
        expect(find.text(strings.planEvaluationMissing), findsNothing);
      },
          () => MockClient(
              (_) async => http.Response('{"error":"Denied"}', 403)));
    });
  }
  test('malformed and foreign evaluation records are rejected', () async {
    for (final body in [
      {},
      {'evaluations': 'bad'},
      {
        'evaluations': [null]
      },
      {
        'evaluations': [
          {'id': 1, 'child_id': 8}
        ]
      },
    ]) {
      await http.runWithClient(() async {
        await expectLater(
            ApiService.getChildEvaluations(7), throwsFormatException);
      }, () => MockClient((_) async => http.Response(jsonEncode(body), 200)));
    }
  });
}
