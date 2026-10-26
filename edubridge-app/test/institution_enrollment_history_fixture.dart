import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_enrollment_history_repository.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

class InstitutionHistoryFixture {
  final academic = InstitutionAcademicFixture();
  List<Map<String, dynamic>> rows = [
    {'id': 2, 'child_id': 9, 'child_name': 'نور', 'section_id': 30,
      'academic_year_id': 10, 'status': 'active', 'enrolled_on': '2026-10-01', 'left_on': null},
    {'id': 1, 'child_id': 8, 'child_name': 'أحمد', 'section_id': 30,
      'academic_year_id': 10, 'status': 'withdrawn', 'enrolled_on': '2026-09-01', 'left_on': '2026-09-30'},
  ];
  int status = 200;
  final paths = <String>[];
  InstitutionEnrollmentHistoryRepository get repository => InstitutionEnrollmentHistoryRepository(
    organizationSlug: 'demo-institution', organizationId: 4, schoolId: 5,
    client: EnrollmentApiClient(get: (path) async {
      paths.add(path);
      if (path == '/institutions/demo-institution/schools/5/academic/student-enrollments') {
        return http.Response(jsonEncode({'enrollments': rows}), status,
          headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return academic.get(path);
    }, post: (path, body) async => throw StateError('Read only')),
  );
}
