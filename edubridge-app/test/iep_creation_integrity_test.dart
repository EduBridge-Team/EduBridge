import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'iep_draft_save_fixture.dart';
import 'iep_http_fixture.dart';

Map<String, dynamic> oldApprovedPlan() => {
      ...iepPlanJson(),
      'id': 20,
      'current_approved_version_id': 401,
      'versions': [
        {
          ...iepVersionJson(id: 401, status: 'approved', number: 1),
          'plan_id': 20
        }
      ],
    };

void main() {
  test(
      'equivalent integer/decimal measurements remain valid in history readback',
      () async {
    final f = IepDraftSaveFixture()..existingPlans.add(oldApprovedPlan());
    f.changeHistory = (plans) {
      for (final plan in plans) {
        for (final version in plan['versions'] as List) {
          for (final goal in version['goals'] as List) {
            goal['baseline'] = (goal['baseline'] as num).toDouble();
            goal['target'] = (goal['target'] as num).toDouble();
          }
        }
      }
    };
    expect((await f.repository.create(saveDraft(), 'a' * 32)).plan.id, 10);
  });
  test('a new draft preserves all earlier approved plans', () async {
    final f = IepDraftSaveFixture()..existingPlans.add(oldApprovedPlan());
    expect((await f.repository.create(saveDraft(), 'a' * 32)).plan.id, 10);
    expect(f.posts, hasLength(1));
  });
  for (final mode in [
    'title',
    'approved-content',
    'deleted',
    'extra-plan',
    'draft-author',
    'draft-goal-id'
  ]) {
    test('new draft cannot confirm changed history $mode', () async {
      final f = IepDraftSaveFixture()..existingPlans.add(oldApprovedPlan());
      f.changeHistory = (plans) {
        switch (mode) {
          case 'title':
            plans.first['title'] = 'Rewritten plan';
          case 'approved-content':
            (plans.first['versions'] as List).single['summary'] =
                'Rewritten content';
          case 'deleted':
            plans.removeAt(0);
          case 'extra-plan':
            plans.add({
              ...oldApprovedPlan(),
              'id': 21,
              'versions': [
                {
                  ...iepVersionJson(id: 402, status: 'approved', number: 1),
                  'plan_id': 21
                }
              ],
              'current_approved_version_id': 402
            });
          case 'draft-author':
            // Only the readback changes, not the already-decoded receipt.
            (plans.last['versions'] as List).single['created_by_name'] =
                'Other author';
          case 'draft-goal-id':
            ((plans.last['versions'] as List).single['goals'] as List)
                .single['id'] = 999;
        }
      };
      await expectLater(
          f.repository.create(saveDraft(), 'a' * 32),
          throwsA(isA<EnrollmentApiException>().having(
              (e) => e.failure, 'failure', EnrollmentFailure.uncertain)));
      expect(f.posts, hasLength(1));
    });
  }
}
