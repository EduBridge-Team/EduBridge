import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/evaluations/evaluation_history_repository.dart';
import 'package:http/http.dart' as http;

const originalHistoryPlan =
    'خطة فردية أصلية\nخطوة أولى للطفل — بلا تغيير أو ترجمة';
Map<String, dynamic> evaluationJson({
  int id = 11,
  int child = 8,
  String date = '2026-10-25T08:00:00Z',
}) => {
  'id': id,
  'child_id': child,
  'created_at': date,
  'evaluation_type': id == 10 ? 'initial' : 'follow_up',
  'evaluator_name': 'المختص — Specialist',
  'cognitive_assessment': 'ملاحظات معرفية أصلية',
  'motor_assessment': 'ملاحظات حركية',
  'emotional_assessment': 'تفاعل أصلي',
  'social_assessment': 'ملاحظات اجتماعية',
  'recommendations': 'توصيات أصلية',
  'educational_plan': id == 10 ? 'الخطة الأقدم' : originalHistoryPlan,
  'teaching_methods': ['تعليم بصري', 'طريقة المختص الأصلية'],
};

class EvaluationHistoryHttpFixture {
  List<Map<String, dynamic>> records = [
    evaluationJson(id: 10, date: '2026-09-01 09:00:00+00'),
    evaluationJson(),
  ];
  int reads = 0, status = 200;
  Completer<http.Response>? pending;
  final paths = <String>[];
  EvaluationHistoryRepository get repository => EvaluationHistoryRepository(
    childId: 8,
    client: EnrollmentApiClient(
      get: get,
      post: (path, body) async {
        throw StateError('Read-only history must never POST');
      },
    ),
  );
  Future<http.Response> get(String path) async {
    if (path != '/evaluations/child/8')
      throw StateError('Unexpected GET $path');
    paths.add(path);
    reads++;
    if (pending != null) return pending!.future;
    return http.Response(
      jsonEncode({'evaluations': records}),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
