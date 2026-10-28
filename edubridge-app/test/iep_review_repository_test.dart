import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/model/iep/iep_review.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_review_repository.dart';
import 'iep_draft_save_fixture.dart';

void main() {
  for (final action in IepReviewAction.values) {
    test('confirmed ${action.name} preserves content and verifies history', () async {
      final initial = newSavedPlan();
      if (action != IepReviewAction.submit) (initial['versions'] as List).single['status'] = 'submitted';
      final plan = IepPlan.fromJson(initial), sourceVersion = IepPlan.fromJson(initial).versions.single;
      // Source must use the exact version belonging to its plan.
      expect(() => IepReviewSource(plan, sourceVersion), throwsFormatException);
      final source = IepReviewSource(plan, plan.versions.single);
      var saved = false, posts = 0, reads = 0;
      final result = jsonDecode(jsonEncode(initial)) as Map<String, dynamic>;
      (result['versions'] as List).single['status'] = switch (action) {
        IepReviewAction.submit => 'submitted', IepReviewAction.returnForChanges => 'returned', IepReviewAction.approve => 'approved',
      };
      if (action == IepReviewAction.returnForChanges) (result['versions'] as List).single['return_reason'] = 'توضيح الهدف';
      if (action == IepReviewAction.approve) result['current_approved_version_id'] = source.version.id;
      final repository = IepReviewRepository(source: source, client: EnrollmentApiClient(
        get: (path) async {
          if (path.endsWith('review-options')) return http.Response(jsonEncode({
            'contract_version': 1, 'child_id': 8, 'plan_id': plan.id, 'version_id': source.version.id,
            'revision': 'r1', 'allowed_actions': [iepReviewActionName(action)],
          }), 200, headers: iepSaveHeaders);
          reads++;
          return http.Response(jsonEncode({'child_id': 8, 'plans': [saved ? result : initial]}), 200, headers: iepSaveHeaders);
        },
        post: (path, body) async {
          posts++; saved = true;
          expect(body['expected_revision'], 'r1');
          expect(body['action'], iepReviewActionName(action));
          expect(body.containsKey('reason'), action == IepReviewAction.returnForChanges);
          return http.Response(jsonEncode({'child_id': 8, 'plan_id': plan.id, 'version_id': source.version.id,
            'request_key': body['request_key'], 'revision': 'r2', 'action': body['action'], 'plan': result}),
            200, headers: iepSaveHeaders);
        },
      ));
      final options = await repository.load();
      await repository.act(action, options, 'a' * 32,
        reason: action == IepReviewAction.returnForChanges ? 'توضيح الهدف' : '');
      expect(posts, 1); expect(reads, 3);
    });
  }
  test('revoked permission prevents POST even after confirmation', () async {
    final plan = IepPlan.fromJson(newSavedPlan());
    var allowed = true, posts = 0;
    final source = IepReviewSource(plan, plan.versions.single);
    final repository = IepReviewRepository(source: source, client: EnrollmentApiClient(
      get: (path) async => http.Response(jsonEncode(path.endsWith('review-options') ? {
        'contract_version': 1, 'child_id': 8, 'plan_id': plan.id, 'version_id': source.version.id,
        'revision': 'r1', 'allowed_actions': allowed ? ['submit'] : <String>[],
      } : {'child_id': 8, 'plans': [newSavedPlan()]}), 200, headers: iepSaveHeaders),
      post: (_, body) async { posts++; return http.Response('{}', 200); },
    ));
    final options = await repository.load(); allowed = false;
    await expectLater(repository.act(IepReviewAction.submit, options, 'a' * 32), throwsA(
      isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.forbidden)));
    expect(posts, 0);
  });
}
