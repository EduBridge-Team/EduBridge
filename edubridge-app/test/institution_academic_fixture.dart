import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_academic_repository.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> institutionAcademicJson() => {
  'school': {'id': 5, 'organization_id': 4, 'name': 'مدرسة الأمل — Hope'},
  'academic_years': [
    {
      'id': 10,
      'school_id': 5,
      'name': '2026–2027',
      'starts_on': '2026-09-01',
      'ends_on': '2027-06-30',
      'is_current': true,
    },
  ],
  'grades': [
    {'id': 20, 'school_id': 5, 'name': 'الصف الثاني'},
  ],
  'sections': [
    {
      'id': 30,
      'academic_year_id': 10,
      'grade_id': 20,
      'name': 'شعبة الأمل',
      'capacity': null,
      'homeroom_teacher_name': 'المعلم محمود',
    },
  ],
  'academic_terms': [
    {
      'id': 40,
      'academic_year_id': 10,
      'name': 'الفصل الأول',
      'position': 1,
      'starts_on': '2026-09-01',
      'ends_on': '2027-01-31',
    },
  ],
  'subjects': [
    {
      'id': 50,
      'school_id': 5,
      'name': 'اللغة العربية',
      'code': 'AR',
      'is_active': true,
    },
  ],
};

class InstitutionAcademicFixture {
  Map<String, dynamic> data = institutionAcademicJson();
  String slug = 'demo-institution';
  int status = 200;
  final paths = <String>[];
  InstitutionAcademicRepository get repository => InstitutionAcademicRepository(
    organizationSlug: 'demo-institution',
    schoolId: 5,
    client: EnrollmentApiClient(
      get: get,
      post: (_, _) async => throw StateError('Read-only API'),
    ),
  );
  Future<http.Response> get(String path) async {
    paths.add(path);
    if (path == '/institutions/my-organization') {
      return http.Response(
        jsonEncode({
          'organization': {'id': 4, 'slug': slug},
        }),
        200,
      );
    }
    if (path != '/institutions/demo-institution/schools/5/academic')
      throw StateError(path);
    return http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
