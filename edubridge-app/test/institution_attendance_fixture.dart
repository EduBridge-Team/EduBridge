import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_attendance_repository.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

class InstitutionAttendanceFixture {
  final academic = InstitutionAcademicFixture();
  int status = 200;
  bool filterDates = true;
  Map<String, dynamic>? detailSession;
  final paths = <String>[];
  List<Map<String, dynamic>> sessions = [
    <String, dynamic>{'id': 60, 'section_id': 30, 'subject_id': 50,
      'attendance_date': '2026-10-26', 'period_number': 1, 'status': 'open', 'notes': 'ملاحظة الجلسة'},
  ];
  List<Map<String, dynamic>> records = [
    <String, dynamic>{'id': 70, 'attendance_session_id': 60, 'child_id': 9,
      'child_name': 'نور', 'status': 'present', 'note': null},
    <String, dynamic>{'id': 71, 'attendance_session_id': 60, 'child_id': 8,
      'child_name': 'أحمد', 'status': 'absent', 'note': 'عذر مكتوب'},
  ];
  InstitutionAttendanceRepository get repository => InstitutionAttendanceRepository(
    organizationSlug: 'demo-institution', organizationId: 4, schoolId: 5,
    client: EnrollmentApiClient(get: (path) async {
      paths.add(path);
      final uri = Uri.parse(path);
      const root = '/institutions/demo-institution/schools/5/attendance';
      Map<String, dynamic>? body;
      if (uri.path == root) {
        body = {'attendance_sessions': sessions.where((s) => !filterDates || uri.queryParameters['date'] == null || s['attendance_date'] == uri.queryParameters['date']).toList()};
      } else if (uri.path == '$root/60') {
        body = {'attendance_session': detailSession ?? sessions.first, 'records': records};
      }
      if (body == null) return academic.get(path);
      return http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});
    }, post: (path, body) async => throw StateError('Attendance view must not write')),
  );
}
