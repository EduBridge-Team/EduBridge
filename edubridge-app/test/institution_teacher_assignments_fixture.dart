import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_teacher_assignments_repository.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

class InstitutionAssignmentsFixture {
  final academic = InstitutionAcademicFixture();
  final teachers = <Map<String, dynamic>>[{'id': 7, 'name': 'المعلم أحمد'}];
  final assignments = <Map<String, dynamic>>[];
  final writes = <Map<String, dynamic>>[];
  final deletions = <String>[];
  bool applyRemoval = true;
  int deleteStatus = 200, readStatus = 200;
  Map<String, dynamic> deleteResponse = {'removed': true};
  Future<void> Function()? beforeDelete;
  void Function()? afterDelete;
  void addAssignment() => assignments.add(<String, dynamic>{'id': 100, 'teacher_id': 7,
    'section_id': 30, 'subject_id': 50, 'teacher_name': 'المعلم أحمد'});
  bool confirm = true, tamper = false;
  int status = 201;
  InstitutionTeacherAssignmentsRepository get repository => InstitutionTeacherAssignmentsRepository(
    organizationSlug: 'demo-institution', organizationId: 4, schoolId: 5,
    client: EnrollmentApiClient(get: (path) async {
      if (path.endsWith('/participants')) return http.Response(jsonEncode({
        'teachers': teachers, 'teacher_assignments': assignments,
      }), readStatus, headers: {'content-type': 'application/json; charset=utf-8'});
      return academic.get(path);
    }, delete: (path) async {
      deletions.add(path); await beforeDelete?.call();
      if (applyRemoval && deleteStatus == 200) assignments.removeWhere((a) => path.endsWith('/${a['id']}'));
      afterDelete?.call();
      return http.Response(jsonEncode(deleteResponse), deleteStatus);
    }, post: (path, body) async {
      if (path != '/institutions/demo-institution/schools/5/academic/teacher-assignments') throw StateError(path);
      writes.add(Map.from(body));
      if (status != 201) return http.Response('{}', status);
      if (confirm) assignments.add({
        ...body, 'id': 100, 'teacher_name': 'المعلم أحمد',
        if (tamper) 'section_id': 999,
      });
      return http.Response('{"assigned":true}', 201);
    }),
  );
}
