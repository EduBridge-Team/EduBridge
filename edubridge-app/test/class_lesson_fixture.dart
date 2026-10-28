import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/services/class_lesson_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';

Map<String, dynamic> classLessonSection(int id, String name) => {
  'section_id': id, 'school_id': id, 'academic_year_id': id,
  'section_name': name, 'school_name': 'School $id', 'academic_year_name': '2026/2027',
  'lessons': [{ 'lesson_id': id * 10, 'title': 'عنوان الدرس الأصلي $id', 'students': [{
    'child_id': id * 100, 'child_name': 'طالب $id', 'state': 'in_progress', 'score': 0, 'maximum': 10,
    'adaptation_summary': 'وقت إضافي — original authored adaptation',
    'iep_goal': {'child_id': id * 100, 'plan_id': id * 2, 'version_id': id * 3,
      'goal_id': id * 4, 'title': 'هدف الطالب $id', 'version_status': 'approved', 'is_current_approved': true},
  }]}],
};
class ClassLessonFixture {
  int status = 200, reads = 0;
  Map<String, dynamic> data = {'contract_version': 1, 'sections': [classLessonSection(1, 'A'), classLessonSection(2, 'B')]};
  ClassLessonRepository get repository => ClassLessonRepository(client: EnrollmentApiClient(
    get: (path) async {
      if (path != '/teachers/me/class-lessons') throw StateError('Unexpected route');
      reads++;
      return http.Response(jsonEncode(data), status, headers: {'content-type': 'application/json; charset=utf-8'});
    }, post: (_, body) async => throw StateError('Read only'),
  ));
}
