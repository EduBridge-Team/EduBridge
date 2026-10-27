import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'iep_draft_save_fixture.dart';

const requestKey = '0123456789abcdef0123456789abcdef';
Matcher failsSave(EnrollmentFailure failure) => throwsA(isA<EnrollmentApiException>()
    .having((e) => e.failure, 'failure', failure));

void main() {
  test('creates only an authorized new draft and confirms the same saved version', () async {
    final f = IepDraftSaveFixture();
    final saved = await f.repository.create(saveDraft(), requestKey);
    expect(saved.plan.id, 10);
    expect(saved.version.id, 103);
    expect(f.posts.single, {
      'request_key': requestKey, 'evaluation_id': 11, 'title': 'خطة جديدة',
      'summary': 'خطة فردية محفوظة بصياغة المختص الأصلية', 'starts_on': '2026-09-01',
      'ends_on': '2027-06-30', 'review_on': '2027-01-01',
      'goals': [{'title': 'هدف فردي أصلي — قراءة كلمات مألوفة باستقلالية',
        'baseline': 2, 'target': 8, 'unit': 'كلمات في المحاولة',
        'measurement_method': 'ملاحظة مباشرة مع تسجيل المحاولات',
        'responsible_name': 'المعلم — Teacher', 'starts_on': '2026-09-01', 'ends_on': '2027-06-01'}],
      'accommodations': ['وقت إضافي حسب حاجة الطفل'],
    });
    expect(f.paths, ['/children/8/iep-draft-options', '/children/8/iep-plans',
      '/children/8/iep-plans', '/children/8/iep-plans']);
  });
  for (final status in [401, 403, 404, 501]) {
    test('unavailable or denied options never POST: $status', () async {
      final f = IepDraftSaveFixture()..optionsStatus = status;
      await expectLater(f.repository.create(saveDraft(), requestKey), throwsA(isA<EnrollmentApiException>()));
      expect(f.posts, isEmpty);
    });
  }
  test('permission and reference eligibility are rechecked immediately before creation', () async {
    final f = IepDraftSaveFixture();
    final repo = f.repository;
    await repo.options();
    f.canCreate = false;
    await expectLater(repo.create(saveDraft(), requestKey), failsSave(EnrollmentFailure.forbidden));
    f.canCreate = true; f.evaluationIds = [12];
    await expectLater(repo.create(saveDraft(), requestKey), failsSave(EnrollmentFailure.conflict));
    expect(f.posts, isEmpty);
  });
  for (final invalid in [
    {'child_id': 9, 'can_create_draft': true, 'evaluation_ids': [11]},
    {'child_id': 8, 'can_create_draft': 'true', 'evaluation_ids': [11]},
    {'child_id': 8, 'can_create_draft': true, 'evaluation_ids': [11, 11]},
  ]) {
    test('invalid options cannot authorize a write: $invalid', () async {
      final f = IepDraftSaveFixture()..optionsOverride = invalid;
      await expectLater(f.repository.create(saveDraft(), requestKey), failsSave(EnrollmentFailure.invalidResponse));
      expect(f.posts, isEmpty);
    });
  }
  for (final problem in ['child', 'key', 'content', 'target', 'evaluation', 'approved', 'duplicate', 'missing']) {
    test('unconfirmed $problem cannot report success and never replays POST', () async {
      final f = IepDraftSaveFixture();
      if (problem == 'child') f.changeReceipt = (r) => r['child_id'] = 9;
      if (problem == 'key') f.changeReceipt = (r) => r['request_key'] = 'other';
      if (problem == 'content') f.plan['title'] = 'Different plan';
      if (problem == 'target') ((f.plan['versions'] as List).first['goals'] as List).first['target'] = 9;
      if (problem == 'evaluation') (f.plan['versions'] as List).first['evaluation_id'] = 12;
      if (problem == 'approved') (f.plan['versions'] as List).first['status'] = 'approved';
      if (problem == 'duplicate') f.duplicateId = true;
      if (problem == 'missing') f.failConfirmation = true;
      await expectLater(f.repository.create(saveDraft(), requestKey), failsSave(EnrollmentFailure.uncertain));
      expect(f.posts, hasLength(1));
    });
  }
}
