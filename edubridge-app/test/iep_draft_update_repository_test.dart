import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_draft_update_repository.dart';
import 'iep_draft_save_fixture.dart';

void main() {
  test('options gate and revision are rechecked before one verified update', () async {
    final plan = IepPlan.fromJson(newSavedPlan());
    final source = IepEditSource.capture(plan, plan.versions.single);
    var revision = 'r1', patches = 0;
    final repository = IepDraftUpdateRepository(source: source, client: EnrollmentApiClient(
      get: (path) async => http.Response(jsonEncode(path.endsWith('edit-options') ? {
        'contract_version': 1, 'child_id': 8, 'plan_id': source.planId,
        'version_id': source.versionId, 'can_edit': true, 'revision': revision, 'evaluation_ids': [11],
      } : {'child_id': 8, 'plans': [newSavedPlan()]}), 200, headers: iepSaveHeaders),
      patch: (path, body) async {
        patches++;
        expect(body['expected_revision'], 'r1');
        revision = 'r2';
        return http.Response(jsonEncode({'child_id': 8, 'plan_id': source.planId,
          'version_id': source.versionId, 'revision': revision, 'request_key': body['request_key'],
          'plan': newSavedPlan()}), 200, headers: iepSaveHeaders);
      },
    ));
    final options = await repository.load();
    await repository.update(source.draft, options, 'a' * 32);
    expect(patches, 1);
    await expectLater(repository.update(source.draft, options, 'a' * 32), throwsA(
      isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.conflict)));
    expect(patches, 1);
  });
  test('unavailable options never send a mutation', () async {
    final plan = IepPlan.fromJson(newSavedPlan());
    var patches = 0;
    final repository = IepDraftUpdateRepository(source: IepEditSource.capture(plan, plan.versions.single),
      client: EnrollmentApiClient(get: (_) async => http.Response('{}', 404),
        patch: (_, body) async { patches++; return http.Response('{}', 200); }));
    await expectLater(repository.load(), throwsA(isA<EnrollmentApiException>().having(
      (e) => e.failure, 'failure', EnrollmentFailure.unavailable)));
    expect(patches, 0);
  });
}
