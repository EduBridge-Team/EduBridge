import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/model/iep/iep_version.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'iep_http_fixture.dart';

Map<String, dynamic> withVersion(Map<String, dynamic> version) => {
  'child_id': 8,
  'plans': [
    {
      ...iepPlanJson(),
      'current_approved_version_id': null,
      'versions': [version],
    },
  ],
};
void main() {
  test(
    'server designated approved version remains distinct from a newer draft',
    () {
      final history = IepPlanHistory.fromJson(8, iepHistoryJson());
      final plan = history.plans.single;
      expect(plan.versions.first.number, 2);
      expect(plan.versions.first.status, IepVersionStatus.draft);
      expect(plan.currentApprovedId, 101);
      expect(plan.versions.last.status, IepVersionStatus.approved);
      expect(plan.versions.first.goals.single.title, iepGoalText);
      for (final action in [
        () => history.plans.clear(),
        () => plan.versions.clear(),
        () => plan.versions.first.goals.clear(),
        () => plan.versions.first.accommodations.clear(),
        () => plan.versions.first.comments.clear(),
      ]) {
        expect(action, throwsUnsupportedError);
      }
    },
  );
  test(
    'lower and equal targets are valid; no progress percentage is invented',
    () {
      for (final target in [1, 2]) {
        final data = IepPlanHistory.fromJson(
          8,
          withVersion({
            ...iepVersionJson(),
            'goals': [
              {...iepGoalJson(), 'target': target},
            ],
          }),
        );
        expect(data.plans.single.versions.single.goals.single.target, target);
      }
    },
  );
  final invalid = <String, Map<String, dynamic>>{
    'foreign root child': {...iepHistoryJson(), 'child_id': 9},
    'missing root scope': {
      'plans': [iepPlanJson()],
    },
    'duplicate plans': {
      'child_id': 8,
      'plans': [iepPlanJson(), iepPlanJson()],
    },
    'foreign version child': withVersion({...iepVersionJson(), 'child_id': 9}),
    'foreign plan reference': withVersion({...iepVersionJson(), 'plan_id': 9}),
    'duplicate version number': {
      'child_id': 8,
      'plans': [
        {
          ...iepPlanJson(),
          'versions': [iepVersionJson(), iepVersionJson(id: 103)],
        },
      ],
    },
    'approved pointer to draft': {
      'child_id': 8,
      'plans': [
        {...iepPlanJson(), 'current_approved_version_id': 102},
      ],
    },
    'missing approved pointer': {
      'child_id': 8,
      'plans': [iepPlanJson()..remove('current_approved_version_id')],
    },
    'unknown state': withVersion({...iepVersionJson(), 'status': 'pending'}),
    'approved version with stale return reason': withVersion({
      ...iepVersionJson(status: 'approved'),
      'return_reason': 'Old rejection',
    }),
    'submitted version with stale return reason': withVersion({
      ...iepVersionJson(status: 'submitted'),
      'return_reason': 'Old rejection',
    }),
    'returned without reason': withVersion({
      ...iepVersionJson(status: 'returned'),
      'return_reason': ' ',
    }),
    'goal scope': withVersion({
      ...iepVersionJson(),
      'goals': [iepGoalJson(version: 999)],
    }),
    'missing baseline': withVersion({
      ...iepVersionJson(),
      'goals': [iepGoalJson()..remove('baseline')],
    }),
    'missing unit': withVersion({
      ...iepVersionJson(),
      'goals': [
        {...iepGoalJson(), 'unit': ''},
      ],
    }),
    'goal dates outside plan': withVersion({
      ...iepVersionJson(),
      'goals': [
        {...iepGoalJson(), 'ends_on': '2028-01-01'},
      ],
    }),
    'invalid calendar day': withVersion({
      ...iepVersionJson(),
      'review_on': '2027-02-30',
    }),
    'comment scope': withVersion({
      ...iepVersionJson(),
      'review_comments': [
        {
          'id': 1,
          'plan_version_id': 9,
          'text': 'Note',
          'created_at': '2026-10-25T08:00:00Z',
        },
      ],
    }),
    'invalid goal numeric type': withVersion({
      ...iepVersionJson(),
      'goals': [
        {...iepGoalJson(), 'target': '8'},
      ],
    }),
    'nonfinite target': withVersion({
      ...iepVersionJson(),
      'goals': [
        {...iepGoalJson(), 'target': double.nan},
      ],
    }),
  };
  for (final entry in invalid.entries) {
    test(
      'rejects ${entry.key}',
      () => expect(
        () => IepPlanHistory.fromJson(8, entry.value),
        throwsFormatException,
      ),
    );
  }
  test('existing approved versions need not be consecutive or inferred from timestamps', () {
    final plan = {
      ...iepPlanJson(),
      'versions': [iepVersionJson(id: 101, number: 3, status: 'approved')],
      'current_approved_version_id': 101,
    };
    expect(
      IepPlanHistory.fromJson(8, {
        'child_id': 8,
        'plans': [plan],
      }).plans.single.versions.single.number,
      3,
    );
  });
  test(
    'repository reads proposed child-scoped endpoint and validates response',
    () async {
      final fixture = IepHttpFixture();
      expect((await fixture.repository.load()).childId, 8);
      expect(fixture.reads, ['/children/8/iep-plans']);
      fixture.payload = {...iepHistoryJson(), 'child_id': 9};
      await expectLater(
        fixture.repository.load(),
        throwsA(
          isA<EnrollmentApiException>().having(
            (e) => e.failure,
            'failure',
            EnrollmentFailure.invalidResponse,
          ),
        ),
      );
    },
  );
  test('missing endpoint is an error, never an empty plans list', () async {
    final fixture = IepHttpFixture()..status = 404;
    await expectLater(
      fixture.repository.load(),
      throwsA(
        isA<EnrollmentApiException>().having(
          (e) => e.failure,
          'failure',
          EnrollmentFailure.unavailable,
        ),
      ),
    );
  });
}
