import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/services/teacher_sections_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
Map<String, dynamic> sectionJson(Object data) => jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
class TeacherSectionsFixture {
  Map<String, dynamic> data = sectionJson({'contract_version': 1, 'sections': [for (final id in [1, 2]) {
    'section_id': id, 'school_id': id, 'academic_year_id': id, 'section_name': 'شعبة $id',
    'school_name': 'مدرسة $id', 'academic_year_name': '2026/2027',
    'subjects': [{'subject_id': id, 'name': 'مادة $id'}],
  }]});
  final rosters = <int, Map<String, dynamic>>{for (final id in [1, 2]) id: sectionJson({
    'contract_version': 1, 'section_id': id, 'school_id': id, 'academic_year_id': id,
    'students': [{'id': id * 100, 'name': 'طالب $id'}, {'id': id * 100 + 1, 'name': 'زميل $id', 'progress_percentage': 0}],
  })};
  int sectionStatus = 200, rosterStatus = 200, reads = 0, rosterReads = 0;
  TeacherSectionsRepository get repository => TeacherSectionsRepository(client: EnrollmentApiClient(get: (path) async {
    if (path == '/teachers/me/sections') { reads++; return response(data, sectionStatus); }
    for (final id in [1, 2]) {
      if (path == '/teachers/me/sections/$id/students') { rosterReads++; return response(rosters[id]!, rosterStatus); }
    }
    throw StateError('Unscoped request $path');
  }, post: (path, body) async => throw StateError('Read only')));
  http.Response response(Object value, int status) => http.Response(jsonEncode(value), status,
    headers: {'content-type': 'application/json; charset=utf-8'});
}
