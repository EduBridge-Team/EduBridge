import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_academic_repository.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

class InstitutionAcademicWriteFixture {
  Map<String, dynamic> data = jsonDecode(jsonEncode(institutionAcademicJson()));
  final writes = <({String path, Map<String, dynamic> body})>[];
  final reads = <String>[];
  int status = 201, readStatus = 200;
  bool failRefresh = false, tamper = false;
  String slug = 'demo-institution';
  Completer<void>? pending;
  InstitutionAcademicRepository get repository => InstitutionAcademicRepository(
    organizationSlug: 'demo-institution',
    schoolId: 5,
    client: EnrollmentApiClient(get: get, post: post),
  );
  Future<http.Response> get(String path) async {
    reads.add(path);
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
      failRefresh && writes.isNotEmpty ? 503 : readStatus,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    writes.add((path: path, body: Map<String, dynamic>.from(body)));
    if (pending != null) await pending!.future;
    if (status != 201) return http.Response('{}', status);
    final kind = path.split('/').last;
    if (!['years', 'grades', 'sections'].contains(kind)) throw StateError(path);
    final item = <String, dynamic>{
      'id': 100 + writes.length,
      ...body,
      if (kind != 'sections') 'school_id': 5,
    };
    final collection = kind == 'years' ? 'academic_years' : kind;
    if (kind == 'years' && body['is_current'] == true) {
      for (final year in data['academic_years'] as List) {
        year['is_current'] = false;
      }
    }
    (data[collection] as List).add(item);
    final key = switch (kind) {
      'years' => 'academic_year',
      'grades' => 'grade',
      _ => 'section',
    };
    return http.Response(
      jsonEncode({
        key: {...item, if (tamper) 'name': 'Wrong receipt'},
      }),
      201,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
