import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/class_lessons/class_lesson_catalog.dart';
import 'package:edubridge_app/model/class_lessons/class_lesson_result.dart';
import 'package:edubridge_app/services/class_result_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'class_lesson_fixture.dart';

Map<String, dynamic> resultJson(Object value) => jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
class ClassResultFixture {
  ClassResultFixture({bool goal = true, bool assignment = true}) {
    final raw = resultJson(classLessonSection(1, 'A'));
    final lesson = (raw['lessons'] as List).single as Map;
    if (assignment) lesson['assignment_id'] = 77;
    if (!goal) (lesson['students'] as List).single['iep_goal'] = null;
    final section = ClassLessonSection.fromJson(raw);
    source = ClassResultSource(section: section, lesson: section.lessons.single, student: section.lessons.single.students.single);
    data = resultJson({'contract_version': 1, ...source.identity,
      'can_record': true, 'revision': 'r1', 'allowed_states': ['in_progress', 'completed'],
      'earliest_on': '2026-10-01', 'latest_on': '2026-10-28',
      'iep_goal': (lesson['students'] as List).single['iep_goal'], 'goal_unit': goal ? 'عدد المحاولات' : null});
  }
  late final ClassResultSource source;
  late Map<String, dynamic> data;
  int reads = 0, posts = 0, status = 200, postStatus = 201, followStatus = 200;
  bool lost = false;
  Map<String, dynamic>? body, receipt;
  Future<void> Function()? beforePost;
  void Function(Map<String, dynamic>)? changeReceipt, changeFollow;
  ClassResultOptions get options => ClassResultOptions.fromJson(data, source);
  ClassResultDraft draft({bool measure = true, bool score = true}) => ClassResultDraft(
    state: 'completed', observedOn: DateTime(2026, 10, 28), observation: 'دليل الأداء الأصلي',
    score: score ? 0 : null, maximum: score ? 10 : null, goalValue: measure ? 2 : null);
  String get root => '/sections/1/lesson-assignments/77/students/100';
  http.Response response(Object value, int status) => http.Response(jsonEncode(value), status,
    headers: {'content-type': 'application/json; charset=utf-8'});
  ClassResultRepository get repository => ClassResultRepository(source: source, client: EnrollmentApiClient(
    get: (path) async {
      if (path == '$root/result-options') { reads++; return response(data, status); }
      if (path == '$root/results/88') {
        final read = resultJson(receipt!); changeFollow?.call(read); return response(read, followStatus);
      }
      throw StateError('Unexpected path $path');
    }, post: (path, payload) async {
      if (path != '$root/results') throw StateError('Unexpected post $path');
      posts++; body = resultJson(payload); await beforePost?.call();
      if (lost) throw Exception('Lost response');
      receipt = resultJson({'contract_version': 1, ...payload, 'status': 'recorded',
        'result_id': 88, 'goal_evidence_id': source.goal == null ? null : 99});
      changeReceipt?.call(receipt!); return response(receipt!, postStatus);
    },
  ));
}
