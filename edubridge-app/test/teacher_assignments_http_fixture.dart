import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/model/schools/teacher_assignment.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/teacher_assignments_repository.dart';
import 'package:http/http.dart' as http;

const firstTeacherName = 'Teacher A — المعلم الأول للتعليم الدامج';
const secondTeacherName = 'Teacher B — المعلم الثاني للتعليم الدامج';
const assignedSubjectName = 'Mathematics — الرياضيات والتعلم التفاعلي';
Map<String, dynamic> assignmentJson({
  int id = 50,
  int teacher = 20,
  int version = 1,
}) => {
  'id': id,
  'school_id': 10,
  'teacher_id': teacher,
  'section_id': 3,
  'subject_id': 8,
  'version': version,
};
Map<String, dynamic> assignmentsPayload() => {
  'school': {'id': 10, 'name': 'School A'},
  'academic_years': [
    {
      'id': 1,
      'school_id': 10,
      'name': '2026/2027 — العام الدراسي الجديد',
      'starts_on': '2026-09-01',
      'ends_on': '2027-06-30',
      'is_current': true,
    },
  ],
  'grades': [
    {'id': 2, 'school_id': 10, 'name': 'Grade 2 — الصف الثاني الأساسي'},
  ],
  'sections': [
    {
      'id': 3,
      'school_id': 10,
      'name': 'Section A — الشعبة الأولى',
      'academic_year_id': 1,
      'grade_id': 2,
      'capacity': 30,
    },
  ],
  'teachers': [
    for (final entry in {
      20: firstTeacherName,
      22: secondTeacherName,
      21: 'Inactive teacher',
    }.entries)
      {
        'id': entry.key,
        'school_id': 10,
        'name': entry.value,
        'role': 'teacher',
        'is_active': entry.key != 21,
      },
  ],
  'subjects': [
    {
      'id': 8,
      'school_id': 10,
      'name': assignedSubjectName,
      'code': 'MATH',
      'is_active': true,
    },
    {
      'id': 9,
      'school_id': 10,
      'name': 'Inactive subject',
      'code': null,
      'is_active': false,
    },
  ],
  'assignments': [assignmentJson()],
};
const newTeacherAssignment = TeacherAssignmentDraft(
  teacherId: 22,
  sectionId: 3,
  subjectId: 8,
);

class TeacherAssignmentsHttpFixture {
  List<Map<String, dynamic>> records = [assignmentJson()];
  int reads = 0, school = 10, contextSchool = 10;
  bool unavailable = false, badReceipt = false, failAfterWrite = false;
  Completer<void>? pending;
  final writes = <Map<String, dynamic>>[];
  TeacherAssignmentsRepository get repository => TeacherAssignmentsRepository(
    client: EnrollmentApiClient(get: get, post: post),
  );
  http.Response response(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
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
    if (path != '/school/teacher-assignments')
      throw StateError('Unexpected GET $path');
    reads++;
    if (unavailable || (failAfterWrite && writes.isNotEmpty))
      return response({}, 404);
    final payload = assignmentsPayload();
    payload['school'] = {'id': school, 'name': 'School A'};
    for (final key in [
      'academic_years',
      'grades',
      'sections',
      'teachers',
      'subjects',
    ]) {
      payload[key] = (payload[key] as List)
          .map((item) => {...item as Map<String, dynamic>, 'school_id': school})
          .toList();
    }
    return response({
      ...payload,
      'assignments': records
          .map((item) => {...item, 'school_id': school})
          .toList(),
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    if (body['expected_school_id'] != 10)
      throw StateError('Foreign school write');
    writes.add({'path': path, ...body});
    if (pending != null) await pending!.future;
    if (path == '/school/teacher-assignments') {
      final item = {
        'id': 51,
        'school_id': 10,
        'version': 1,
        'teacher_id': body['teacher_id'],
        'section_id': body['section_id'],
        'subject_id': body['subject_id'],
      };
      records = [...records, item];
      return response({
        'school_id': 10,
        'assignment': {...item, if (badReceipt) 'teacher_id': 99},
      }, 201);
    }
    final match = RegExp(r'^/school/teacher-assignments/(\d+)/remove$')
        .firstMatch(path);
    if (match == null) throw StateError('Unexpected POST $path');
    final id = int.parse(match[1]!);
    final item = records.singleWhere((item) => item['id'] == id);
    if (body['expected_version'] != item['version']) return response({}, 409);
    records = records.where((item) => item['id'] != id).toList();
    return response({
      'school_id': 10,
      'removed': true,
      'assignment': {
        ...item,
        'version': (item['version'] as int) + (badReceipt ? 0 : 1),
      },
    });
  }
}
