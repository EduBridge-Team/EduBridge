import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_draft.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'iep_update_integrity_fixture.dart';

Matcher failure(EnrollmentFailure value) => throwsA(
    isA<EnrollmentApiException>().having((e) => e.failure, 'failure', value));

void main() {
  test(
      'equivalent measurements do not falsely change the baseline or saved content',
      () async {
    final f = IepUpdateIntegrityFixture();
    final expected = await f.repository.load();
    (f.approved['goals'] as List).single['baseline'] = 2.0;
    f.afterPatch = (_) => (f.draft['goals'] as List).single['target'] = 8.0;
    await f.repository.update(f.source.draft, expected, 'a' * 32);
    expect(f.patches, 1);
  });
  for (final field in ['summary', 'goal', 'comment', 'accommodation']) {
    test('changed approved $field blocks PATCH even if revision is unchanged',
        () async {
      final f = IepUpdateIntegrityFixture();
      final expected = await f.repository.load();
      switch (field) {
        case 'summary':
          f.approved['summary'] = 'Changed approved content';
        case 'goal':
          (f.approved['goals'] as List).single['target'] = 9;
        case 'comment':
          (f.approved['review_comments'] as List).single['text'] =
              'Changed audit';
        case 'accommodation':
          f.approved['accommodations'] = ['Changed accommodation'];
      }
      await expectLater(f.repository.update(f.source.draft, expected, 'a' * 32),
          failure(EnrollmentFailure.conflict));
      expect(f.patches, 0);
    });
  }
  for (final field in [
    'approved-content',
    'approved-goal',
    'approved-pointer',
    'removed-version',
    'author',
    'created',
    'number',
    'comment'
  ]) {
    test('matching receipt and readback cannot hide changed history $field',
        () async {
      final f = IepUpdateIntegrityFixture();
      final expected = await f.repository.load();
      f.afterPatch = (data) {
        switch (field) {
          case 'approved-content':
            f.approved['summary'] = 'Rewritten approved history';
          case 'approved-goal':
            (f.approved['goals'] as List).single['target'] = 9;
          case 'approved-pointer':
            data['current_approved_version_id'] = null;
          case 'removed-version':
            data['versions'] = [f.draft];
          case 'author':
            f.draft['created_by_name'] = 'Replacement author';
          case 'created':
            f.draft['created_at'] = '2026-10-26T08:00:00Z';
          case 'number':
            f.draft['version_number'] = 3;
          case 'comment':
            (f.draft['review_comments'] as List).single['text'] =
                'Rewritten comment';
        }
      };
      await expectLater(f.repository.update(f.source.draft, expected, 'a' * 32),
          failure(EnrollmentFailure.uncertain));
      expect(f.patches, 1);
    });
  }
  test('authored title changes and replacement draft goal IDs remain supported',
      () async {
    final f = IepUpdateIntegrityFixture();
    final old = f.source.draft;
    final changed = IepPlanDraft(
        childId: old.childId,
        evaluationId: old.evaluationId,
        title: 'Updated authored title',
        summary: old.summary,
        start: old.start,
        end: old.end,
        reviewOn: old.reviewOn,
        goals: old.goals,
        accommodations: old.accommodations);
    await f.repository.update(changed, await f.repository.load(), 'a' * 32);
    expect(f.patches, 1);
    expect(f.data['title'], 'Updated authored title');
    expect((f.draft['goals'] as List).single['id'], 900);
    expect(f.approved['summary'], isNot('Rewritten approved history'));
  });
}
