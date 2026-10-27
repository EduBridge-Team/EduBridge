import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_timetable_repository.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

class InstitutionTimetableFixture {
  final academic = InstitutionAcademicFixture();
  int status = 200, postStatus = 201;
  int? assignedTeacher;
  final deletions = <String>[];
  int deleteStatus = 200;
  bool applyWrite = true;
  Map<String, dynamic>? response, createResponse;
  final absences = <Map<String, dynamic>>[];
  Map<String, dynamic>? absenceResponse;
  final creations = <Map<String, dynamic>>[];
  void addSection() {
    final sections = academic.data['sections'] as List;
    academic.data['sections'] = [...sections, <String, dynamic>{...Map<String, dynamic>.from(sections.first as Map),
      'id': 31, 'name': 'شعبة أخرى'}];
  }
  void Function()? afterWrite;
  Future<void> Function()? beforeWrite;
  final paths = <String>[];
  final writes = <Map<String, dynamic>>[];
  final members = <Map<String, dynamic>>[
    {'id': 7, 'name': 'المعلم محمود'}, {'id': 8, 'name': 'المعلمة سارة'}, {'id': 9, 'name': 'المعلم أحمد'},
  ];
  List<Map<String, dynamic>> candidates = [
    {'id': 8, 'name': 'المعلمة سارة'}, {'id': 9, 'name': 'المعلم أحمد'},
  ];
  List<Map<String, dynamic>> rows = [
    {'id': 80, 'school_id': 5, 'academic_year_id': 10, 'section_id': 30,
      'subject_id': 50, 'teacher_id': 7, 'teacher_name': 'المعلم محمود', 'weekday': 2,
      'period_number': 1, 'starts_at': '08:00:00', 'ends_at': '08:45:00', 'room': 'غرفة نور'},
  ];
  http.Response json(Map<String, dynamic> body, int code) => http.Response(jsonEncode(body), code,
    headers: {'content-type': 'application/json; charset=utf-8'});
  InstitutionTimetableRepository get repository => InstitutionTimetableRepository(
    organizationSlug: 'demo-institution', organizationId: 4, schoolId: 5,
    client: EnrollmentApiClient(get: (path) async {
      paths.add(path);
      final uri = Uri.parse(path);
      const root = '/institutions/demo-institution/schools/5';
      if (uri.path == '$root/timetable') return json({'timetable': rows}, status);
      if (uri.path == '$root/participants') return json({'teachers': members, 'teacher_assignments': []}, status);
      if (uri.path == '$root/timetable/80/available-substitutes') {
        return json({'available_teachers': candidates.where((r) => r['id'] != assignedTeacher).toList()}, status);
      }
      return academic.get(path);
    }, delete: (path) async {
      deletions.add(path);
      await beforeWrite?.call();
      if (applyWrite && deleteStatus == 200) rows.removeWhere((r) => path.endsWith('/${r['id']}'));
      afterWrite?.call();
      return json(response ?? {'message': 'Deleted'}, deleteStatus);
    }, post: (path, body) async {
      if (path == '/institutions/demo-institution/schools/5/teacher-absences') {
        paths.add(path); absences.add(body); await beforeWrite?.call(); afterWrite?.call();
        final date = DateTime.parse(body['absence_date'] as String);
        return json(absenceResponse ?? {'absence': {'id': 100, 'school_id': 5,
          ...body, 'status': 'confirmed'}, 'affected_classes': rows.where((r) =>
          r['teacher_id'] == body['teacher_id'] && r['weekday'] == date.weekday % 7 + 1).toList()}, postStatus);
      }
      if (path == '/institutions/demo-institution/schools/5/timetable') {
        paths.add(path); creations.add(body); await beforeWrite?.call();
        final row = <String, dynamic>{...body, 'id': 81, 'school_id': 5,
          'teacher_name': body['teacher_id'] == null ? null : members.singleWhere((t) => t['id'] == body['teacher_id'])['name']};
        if (applyWrite && postStatus == 201) rows.add(row);
        afterWrite?.call();
        final databaseRow = Map<String, dynamic>.from(row)..remove('teacher_name');
        return json(createResponse ?? {'timetable_entry': databaseRow}, postStatus);
      }
      paths.add(path); writes.add(body); await beforeWrite?.call();
      if (applyWrite && postStatus == 201) assignedTeacher = body['substitute_teacher_id'] as int;
      afterWrite?.call();
      return json(response ?? {'substitution': {'id': 90, 'timetable_entry_id': 80,
        'class_date': body['class_date'], 'original_teacher_id': 7,
        'substitute_teacher_id': body['substitute_teacher_id'], 'status': 'assigned', 'notes': body['notes']}}, postStatus);
    }),
  );
}
