import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/model/iep/iep_draft.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_draft_repository.dart';
import 'package:edubridge_app/services/iep/iep_history_repository.dart';
import 'package:http/http.dart' as http;

import 'iep_http_fixture.dart';

const iepSaveHeaders = {'content-type': 'application/json; charset=utf-8'};

IepPlanDraft saveDraft() => IepPlanDraft(
  childId: 8, evaluationId: 11, title: 'خطة جديدة',
  start: DateTime(2026, 9, 1), end: DateTime(2027, 6, 30), reviewOn: DateTime(2027, 1, 1),
  summary: 'خطة فردية محفوظة بصياغة المختص الأصلية',
  accommodations: ['وقت إضافي حسب حاجة الطفل'],
  goals: [IepDraftGoal(title: iepGoalText, baseline: 2, target: 8,
    unit: 'كلمات في المحاولة', method: 'ملاحظة مباشرة مع تسجيل المحاولات',
    responsible: 'المعلم — Teacher', start: DateTime(2026, 9, 1), end: DateTime(2027, 6, 1))],
);
Map<String, dynamic> newSavedPlan() => {
  ...iepPlanJson(), 'title': 'خطة جديدة', 'current_approved_version_id': null,
  'versions': [{...iepVersionJson(id: 103, number: 1), 'review_comments': <Object>[]}],
};

class IepDraftSaveFixture {
  bool canCreate = true, failConfirmation = false, saved = false, duplicateId = false;
  int optionsStatus = 200, postStatus = 201;
  List<int> evaluationIds = [11];
  Map<String, dynamic> plan = newSavedPlan();
  Map<String, dynamic>? optionsOverride;
  final existingPlans = <Map<String, dynamic>>[];
  void Function(List<Map<String, dynamic>>)? changeHistory;
  void Function(Map<String, dynamic>)? changeReceipt;
  Completer<void>? pendingPost;
  final paths = <String>[], posts = <Map<String, dynamic>>[];
  IepDraftRepository get repository => IepDraftRepository(childId: 8, client: client);
  IepHistoryRepository get historyRepository => IepHistoryRepository(childId: 8, client: client);
  EnrollmentApiClient get client => EnrollmentApiClient(
    get: (path) async {
      paths.add(path);
      if (path.endsWith('iep-draft-options')) return http.Response(jsonEncode(optionsOverride ?? {
        'child_id': 8, 'can_create_draft': canCreate, 'evaluation_ids': evaluationIds,
      }), optionsStatus, headers: iepSaveHeaders);
      if (path == '/children/8/iep-plans') {
        final plans = [...existingPlans,
          if ((saved && !failConfirmation) || duplicateId) plan];
        if (saved) changeHistory?.call(plans);
        return http.Response(jsonEncode({'child_id': 8, 'plans': plans}),
          200, headers: iepSaveHeaders);
      }
      throw StateError('Unexpected GET $path');
    },
    post: (path, body) async {
      paths.add(path); posts.add(body);
      if (pendingPost != null) await pendingPost!.future;
      if (postStatus == 201) saved = true;
      final receipt = <String, dynamic>{'child_id': 8, 'request_key': body['request_key'], 'plan': plan};
      changeReceipt?.call(receipt);
      return http.Response(jsonEncode(receipt), postStatus, headers: iepSaveHeaders);
    },
  );
}
