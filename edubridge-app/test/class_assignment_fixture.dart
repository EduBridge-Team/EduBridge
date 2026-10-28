import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/class_lessons/class_lesson_assignment.dart';
import 'package:edubridge_app/model/class_lessons/class_lesson_catalog.dart';
import 'package:edubridge_app/services/class_assignment_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'class_lesson_fixture.dart';

Map<String, dynamic> assignmentJson(Object value) => jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
class ClassAssignmentFixture {
  final section = ClassLessonSection.fromJson(classLessonSection(1, 'A'));
  Map<String, dynamic> data = assignmentJson({
    'contract_version': 1, 'section_id': 1, 'school_id': 1, 'academic_year_id': 1,
    'revision': 'r1', 'can_assign': true, 'lessons': [{'lesson_id': 10, 'title': 'الدرس الأصلي'}],
    'students': [for (final id in [100, 200]) {
      'child_id': id, 'child_name': 'طالب $id',
      'goals': [{'child_id': id, 'plan_id': id + 1, 'version_id': id + 2,
        'goal_id': id + 3, 'title': 'هدف الطالب $id', 'version_status': 'approved', 'is_current_approved': true}],
    }],
  });
  int reads = 0, posts = 0, status = 200, postStatus = 201, followStatus = 200;
  Map<String, dynamic>? body, receipt;
  void Function(Map<String, dynamic>)? changeReceipt, changeFollow;
  bool throwPost = false;
  ClassAssignmentOptions get options => ClassAssignmentOptions.fromJson(data, section);
  ClassAssignmentDraft draft([ClassAssignmentOptions? source]) {
    final o = source ?? options;
    return ClassAssignmentDraft(10, [
      ClassAssignmentChoice(childId: 100, goal: o.students.first.goals.first, adaptation: 'وقت إضافي'),
      const ClassAssignmentChoice(childId: 200),
    ]);
  }
  http.Response response(Object value, int code) => http.Response(jsonEncode(value), code,
    headers: {'content-type': 'application/json; charset=utf-8'});
  ClassAssignmentRepository get repository => ClassAssignmentRepository(section: section, client: EnrollmentApiClient(
    get: (path) async {
      if (path == '/sections/1/lesson-assignments/options') { reads++; return response(data, status); }
      if (path == '/sections/1/lesson-assignments/77') {
        final value = assignmentJson(receipt!); changeFollow?.call(value); return response(value, followStatus);
      }
      throw StateError('Unexpected route $path');
    }, post: (path, payload) async {
      if (path != '/sections/1/lesson-assignments') throw StateError('Unexpected write');
      posts++; body = assignmentJson(payload);
      if (throwPost) throw Exception('Lost response');
      receipt = assignmentJson({'contract_version': 1, 'assignment_id': 77, 'section_id': 1,
        'school_id': 1, 'academic_year_id': 1, 'lesson_id': payload['lesson_id'],
        'request_key': payload['request_key'], 'status': 'assigned', 'students': payload['students']});
      changeReceipt?.call(receipt!);
      return response(receipt!, postStatus);
    },
  ));
}
