import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_draft_update_repository.dart';
import 'iep_http_fixture.dart';

class IepUpdateIntegrityFixture {
  IepUpdateIntegrityFixture() {
    final plan = IepPlan.fromJson(data);
    source = IepEditSource.capture(plan, plan.versions.first);
  }
  Map<String, dynamic> data = iepPlanJson();
  late final IepEditSource source;
  String revision = 'r1';
  int patches = 0;
  void Function(Map<String, dynamic>)? afterPatch;
  Map<String, dynamic> get approved =>
      (data['versions'] as List).first as Map<String, dynamic>;
  Map<String, dynamic> get draft =>
      (data['versions'] as List).last as Map<String, dynamic>;
  http.Response response(Object value) => http.Response(jsonEncode(value), 200,
      headers: {'content-type': 'application/json; charset=utf-8'});

  late final repository = IepDraftUpdateRepository(
      source: source,
      client: EnrollmentApiClient(
        get: (path) async => response(path.endsWith('edit-options')
            ? {
                'contract_version': 1,
                'child_id': 8,
                'plan_id': 10,
                'version_id': 102,
                'can_edit': true,
                'revision': revision,
                'evaluation_ids': [11],
              }
            : {
                'child_id': 8,
                'plans': [data]
              }),
        patch: (_, body) async {
          patches++;
          revision = 'r2';
          data['title'] = body['title'];
          for (final field in [
            'evaluation_id',
            'summary',
            'starts_on',
            'ends_on',
            'review_on',
            'accommodations'
          ]) {
            draft[field] = body[field];
          }
          draft['goals'] = [
            for (final (index, goal) in (body['goals'] as List).indexed)
              {
                ...Map<String, dynamic>.from(goal as Map),
                'id': 900 + index,
                'plan_version_id': 102
              }
          ];
          afterPatch?.call(data);
          return response({
            'child_id': 8,
            'plan_id': 10,
            'version_id': 102,
            'revision': revision,
            'request_key': body['request_key'],
            'plan': data
          });
        },
      ));
}
