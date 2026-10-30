import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/class_lessons/class_lesson_result.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'class_result_fixture.dart';
const resultKey = '0123456789abcdef0123456789abcdef';
Matcher resultFailure(EnrollmentFailure failure) => isA<EnrollmentApiException>().having((e) => e.failure, 'failure', failure);
void main() {
  test('keeps score zero distinct from goal measurement and confirms atomic evidence', () async {
    final f = ClassResultFixture();
    expect(await f.repository.record(f.options, f.draft(), resultKey), 88);
    expect(f.posts, 1); expect(f.body!['score'], 0); expect(f.body!['maximum'], 10);
    expect(f.body!['goal_measurement'], {'value': 2, 'unit': 'عدد المحاولات'});
    expect(f.body!['iep_goal'], {'plan_id': 2, 'version_id': 3, 'goal_id': 4});
    expect(f.body!['observation'], 'دليل الأداء الأصلي');
    expect(() => f.options.states.clear(), throwsUnsupportedError);
  });
  test('observation window is inclusive of the whole calendar day', () {
    final f = ClassResultFixture(), options = f.options;
    final duringLastDay = ClassResultDraft(
      state: 'completed',
      observedOn: DateTime(2026, 10, 28, 23, 59),
      observation: 'end-of-day evidence',
    );
    expect(duringLastDay.fits(options), isTrue);
    expect(duringLastDay.payload(options)['observed_on'], '2026-10-28');
    final outsideWindow = ClassResultDraft(
      state: 'completed',
      observedOn: DateTime(2026, 10, 29),
      observation: 'outside window',
    );
    expect(outsideWindow.fits(options), isFalse);
  });
  test('no score or measurement is valid qualitative evidence; no goal stays unlinked', () async {
    for (final hasGoal in [true, false]) {
      final f = ClassResultFixture(goal: hasGoal);
      expect(await f.repository.record(f.options, f.draft(measure: false, score: false), resultKey), 88);
      expect(f.body!['score'], isNull); expect(f.body!['maximum'], isNull); expect(f.body!['goal_measurement'], isNull);
      expect(f.receipt!['goal_evidence_id'], hasGoal ? 99 : null);
    }
  });
  test('numeric receipt representations compare by value', () async {
    final f = ClassResultFixture()..changeReceipt = (r) { r['score'] = 0.0; (r['goal_measurement'] as Map)['value'] = 2.0; };
    expect(await f.repository.record(f.options, f.draft(), resultKey), 88);
  });
  for (final mode in ['scope', 'assignment', 'child', 'foreign-goal', 'old-goal', 'draft-goal', 'unit', 'dates', 'states', 'empty-enabled-states']) {
    test('rejects invalid result options $mode', () async {
      final f = ClassResultFixture();
      if (mode == 'scope') f.data['school_id'] = 2;
      if (mode == 'assignment') f.data['assignment_id'] = 78;
      if (mode == 'child') f.data['child_id'] = 200;
      if (mode == 'foreign-goal') (f.data['iep_goal'] as Map)['child_id'] = 200;
      if (mode == 'old-goal') (f.data['iep_goal'] as Map)['is_current_approved'] = false;
      if (mode == 'draft-goal') (f.data['iep_goal'] as Map)['version_status'] = 'draft';
      if (mode == 'unit') f.data['goal_unit'] = '';
      if (mode == 'dates') f.data['latest_on'] = '2026-02-30';
      if (mode == 'states') f.data['allowed_states'] = ['completed', 'completed'];
      await expectLater(f.repository.load(), throwsA(resultFailure(EnrollmentFailure.invalidResponse)));
      expect(f.posts, 0);
    });
  }
  test('catalog without assignment identity never requests result endpoint', () async {
    final f = ClassResultFixture(assignment: false);
    await expectLater(f.repository.load(), throwsA(resultFailure(EnrollmentFailure.unavailable)));
    expect(f.reads, 0); expect(f.posts, 0);
  });
  test('invalid input never posts, including score without maximum and nonfinite goal value', () async {
    final f = ClassResultFixture();
    for (final draft in [
      ClassResultDraft(state: 'completed', observedOn: DateTime(2026, 10, 28), observation: 'evidence', score: 0),
      ClassResultDraft(state: 'completed', observedOn: DateTime(2026, 10, 28), observation: 'evidence', score: 11, maximum: 10),
      ClassResultDraft(state: 'completed', observedOn: DateTime(2026, 10, 28), observation: 'evidence', goalValue: double.nan),
      ClassResultDraft(state: 'completed', observedOn: DateTime(2026, 10, 29), observation: 'evidence'),
      ClassResultDraft(state: 'completed', observedOn: DateTime(2026, 10, 28), observation: '  '),
    ]) {
      await expectLater(f.repository.record(f.options, draft, resultKey), throwsA(resultFailure(EnrollmentFailure.validation)));
    }
    expect(f.posts, 0);
  });
  for (final mode in ['revision', 'permission', 'unit', 'states']) {
    test('rechecks options before post $mode', () async {
      final f = ClassResultFixture(), expected = ClassResultFixture().options;
      if (mode == 'revision') f.data['revision'] = 'r2';
      if (mode == 'permission') f.data['can_record'] = false;
      if (mode == 'unit') f.data['goal_unit'] = 'seconds';
      if (mode == 'states') f.data['allowed_states'] = ['in_progress'];
      await expectLater(f.repository.record(expected, f.draft(), resultKey), throwsA(resultFailure(EnrollmentFailure.conflict)));
      expect(f.posts, 0);
    });
  }
  for (final mode in ['child', 'score', 'goal', 'unit', 'evidence', 'key', 'follow-denied', 'follow-evidence', 'lost', 'server']) {
    test('changed receipt/read cannot confirm result $mode', () async {
      final f = ClassResultFixture();
      f.changeReceipt = (r) {
        if (mode == 'child') r['child_id'] = 200;
        if (mode == 'score') r['score'] = 8;
        if (mode == 'goal') r['iep_goal'] = null;
        if (mode == 'unit') (r['goal_measurement'] as Map)['unit'] = 'seconds';
        if (mode == 'evidence') r['goal_evidence_id'] = null;
        if (mode == 'key') r['request_key'] = 'other';
      };
      if (mode == 'follow-denied') f.followStatus = 403;
      if (mode == 'follow-evidence') f.changeFollow = (r) => r['goal_evidence_id'] = 999;
      if (mode == 'lost') f.lost = true;
      if (mode == 'server') f.postStatus = 500;
      await expectLater(f.repository.record(f.options, f.draft(), resultKey), throwsA(resultFailure(EnrollmentFailure.uncertain)));
      expect(f.posts, 1);
    });
  }
}
