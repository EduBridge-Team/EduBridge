import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/iep/iep_goal_evidence.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_goal_evidence_repository.dart';
import 'iep_draft_save_fixture.dart';

IepEvidenceSource evidenceSource() {
  final plan = IepPlan.fromJson(newSavedPlan());
  return IepEvidenceSource(childId: plan.childId, planId: plan.id,
      goal: plan.versions.single.goals.first);
}
Map<String, dynamic> evidenceJson(IepEvidenceSource source) => {
  'contract_version': 1, 'complete': true, 'revision': 'r1',
  'child_id': source.childId, 'plan_id': source.planId,
  'plan_version_id': source.goal.versionId, 'goal_id': source.goal.id,
  'unit': source.goal.unit,
  'evidence': [
    {'id': 1, 'source_label': 'جلسة فردية', 'observation': 'ملاحظة وصفية أصلية',
      'observed_on': '2026-10-01', 'recorded_at': '2026-10-01T12:00:00Z',
      'author_name': 'المختص'},
    {'id': 2, 'source_label': 'نتيجة درس', 'observation': 'قياس صفري موثق',
      'observed_on': '2026-10-02', 'recorded_at': '2026-10-02T14:00:00+02:00',
      'measurement': 0, 'unit': source.goal.unit},
  ],
};
Map<String, dynamic> evidenceCopy(Map<String, dynamic> data) =>
    jsonDecode(jsonEncode(data)) as Map<String, dynamic>;

class EvidenceFixture {
  EvidenceFixture(this.source) : data = evidenceJson(source);
  final IepEvidenceSource source;
  Map<String, dynamic> data;
  final paths = <String>[];
  int status = 200;
  Completer<void>? pending;
  late final repository = IepGoalEvidenceRepository(client: EnrollmentApiClient(
    get: (path) async {
      paths.add(path);
      await pending?.future;
      return http.Response(jsonEncode(data), status,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
}

