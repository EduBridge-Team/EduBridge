import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/model/schools/curriculum_draft.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/curriculum_repository.dart';
import 'package:http/http.dart' as http;

const curriculumYearName = '2026/2027 — العام الدراسي الجديد';
Map<String, dynamic> curriculumYear() => {
  'id': 1,
  'school_id': 10,
  'name': curriculumYearName,
  'starts_on': '2026-09-01',
  'ends_on': '2027-06-30',
  'is_current': true,
};
Map<String, dynamic> curriculumTerm() => {
  'id': 4,
  'school_id': 10,
  'academic_year_id': 1,
  'name': 'First term — الفصل الدراسي الأول',
  'position': 1,
  'starts_on': '2026-09-01',
  'ends_on': '2026-12-31',
};
Map<String, dynamic> curriculumSubject() => {
  'id': 8,
  'school_id': 10,
  'name': 'Mathematics — الرياضيات',
  'code': 'MATH',
  'is_active': false,
};
Map<String, dynamic> curriculumPayload() => {
  'school': {'id': 10, 'name': 'School A'},
  'academic_years': [curriculumYear()],
  'academic_terms': [curriculumTerm()],
  'subjects': [curriculumSubject()],
};
CurriculumDraft termDraft({int position = 2, int year = 1}) => CurriculumDraft(
  kind: CurriculumKind.term,
  name: 'Second term',
  yearId: year,
  position: position,
  start: DateTime(2027, 1, 1),
  end: DateTime(2027, 6, 30),
);
const subjectDraft = CurriculumDraft(
  kind: CurriculumKind.subject,
  name: ' Science ',
  code: ' SCI ',
  active: false,
);

class CurriculumHttpFixture {
  List<Map<String, dynamic>> terms = [curriculumTerm()],
      subjects = [curriculumSubject()];
  int reads = 0, contextSchool = 10, catalogSchool = 10;
  bool noYears = false;
  bool unavailable = false, failAfterWrite = false, badReceipt = false;
  Completer<void>? pending;
  final writes = <Map<String, dynamic>>[];
  CurriculumRepository get repository => CurriculumRepository(
    client: EnrollmentApiClient(get: get, post: post),
  );
  http.Response response(Object data, [int status = 200]) => http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  Future<http.Response> get(String path) async {
    if (path == '/school/context')
      return response({
        'school': {
          'id': contextSchool,
          'name': 'School A',
          'organization_id': null,
        },
      });
    if (path != '/school/academic/curriculum')
      throw StateError('Unexpected GET $path');
    reads++;
    if (unavailable || (failAfterWrite && writes.isNotEmpty))
      return response({}, 404);
    return response({
      ...curriculumPayload(),
      'school': {'id': catalogSchool, 'name': 'School A'},
      'academic_years': noYears
          ? []
          : [
              {...curriculumYear(), 'school_id': catalogSchool},
            ],
      'academic_terms': terms
          .map((term) => {...term, 'school_id': catalogSchool})
          .toList(),
      'subjects': subjects
          .map((subject) => {...subject, 'school_id': catalogSchool})
          .toList(),
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    if (body['expected_school_id'] != 10)
      throw StateError('Foreign school write');
    if (path != '/school/academic/terms' &&
        path != '/school/academic/subjects') {
      throw StateError('Unexpected POST $path');
    }
    writes.add({'path': path, ...body});
    if (pending != null) await pending!.future;
    final item = {
      ...body,
      'school_id': 10,
      'id': path.endsWith('/terms') ? 5 : 9,
    }..remove('expected_school_id');
    if (path.endsWith('/terms')) {
      terms = [...terms, item];
    } else {
      subjects = [...subjects, item];
    }
    return response({
      'school_id': 10,
      'item': {...item, if (badReceipt) 'name': 'Different saved name'},
    }, 201);
  }
}
