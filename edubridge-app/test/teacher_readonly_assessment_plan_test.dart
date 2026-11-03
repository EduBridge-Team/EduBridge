import 'dart:convert';

import 'package:edubridge_app/screens/evaluation_history/evaluation_history_screen.dart';
import 'package:edubridge_app/screens/evaluation_history/evaluation_record_screen.dart';
import 'package:edubridge_app/screens/iep/iep_history_screen.dart';
import 'package:edubridge_app/screens/iep/iep_version_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/teacher_completed_iep_history_repository.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'curriculum_ui_support.dart';
import 'evaluation_history_fixture.dart';
import 'iep_draft_save_fixture.dart';
import 'iep_http_fixture.dart';

void main() {
  for (final locale in ['ar', 'en']) {
    testWidgets('teacher reuses evaluation/plan UI read-only $locale', (tester) async {
      final evaluation = EvaluationHistoryHttpFixture();
      final plans = TeacherCompletedIepHistoryRepository(childId: 8,
        client: EnrollmentApiClient(get: (path) async {
          expect(path, '/teachers/me/children/8/completed-iep-plans');
          final plan = newSavedPlan();
          (plan['versions'] as List).single['status'] = 'completed';
          return http.Response(jsonEncode({
            'contract_version': 1, 'complete': true,
            'child_id': 8, 'plans': [plan],
          }), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }, post: (path, body) async => throw StateError('Teacher must never POST')));
      await tester.pumpWidget(curriculumHost(EvaluationHistoryScreen(
        childId: 8, childName: 'محمود', readOnly: true,
        gateway: evaluation.repository, iepGateway: plans,
      ), locale));
      await tester.pumpAndSettle();
      expect(find.byType(BrandAppBar), findsOneWidget);
      expect(find.byKey(const ValueKey('evaluation-record-11')), findsOneWidget);
      // Legacy embedded educational_plan has no completion status.
      await tester.tap(find.byKey(const ValueKey('evaluation-record-11')));
      await tester.pumpAndSettle();
      expect(find.byType(EvaluationRecordScreen), findsOneWidget);
      expect(find.text(originalHistoryPlan), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-child-iep')));
      await tester.pumpAndSettle();
      expect(find.byType(IepHistoryScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('iep-prepare-draft')), findsNothing);
      expect(find.byKey(const ValueKey('iep-edit-copy-103')), findsNothing);
      expect(find.byKey(const ValueKey('iep-version-103')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('iep-version-103')));
      await tester.pumpAndSettle();
      expect(find.byType(IepVersionScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('iep-open-review')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('readOnly IEP screen rejects a mixed draft/approved catalog', (tester) async {
    final evaluation = EvaluationHistoryHttpFixture();
    final plans = IepHttpFixture();
    await tester.pumpWidget(curriculumHost(EvaluationHistoryScreen(
      childId: 8, readOnly: true,
      gateway: evaluation.repository, iepGateway: plans.repository,
    ), 'ar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-child-iep')));
    await tester.pumpAndSettle();
    expect(find.byType(IepHistoryScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('iep-plan-10')), findsNothing);
    expect(find.byKey(const ValueKey('iep-prepare-draft')), findsNothing);
    expect(find.byKey(const ValueKey('iep-error')), findsOneWidget);
  });
}
