import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_attendance_repository.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

class InstitutionAttendanceFixture {
  final academic = InstitutionAcademicFixture();
  int status = 200;
  bool filterDates = true;
  int postStatus = 201, putStatus = 200;
  bool applyWrites = true;
  Map<String, dynamic>? createResponse;
  Map<String, dynamic> saveResponse = {'message': 'تم حفظ الحضور بنجاح'};
  void Function()? afterWrite;
  Future<void> Function()? beforeWrite;
  final posts = <Map<String, dynamic>>[], puts = <Map<String, dynamic>>[];
  final bySession = <int, List<Map<String, dynamic>>>{};
  List<Map<String, dynamic>> enrollments = [
    for (final id in [9, 8]) <String, dynamic>{'id': id, 'child_id': id,
      'child_name': id == 9 ? 'نور' : 'أحمد', 'section_id': 30, 'academic_year_id': 10,
      'status': 'active', 'enrolled_on': '2026-10-01', 'left_on': null},
  ];
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
      } else if (uri.path == '/institutions/demo-institution/schools/5/academic/student-enrollments') {
        body = {'enrollments': enrollments};
      } else if (uri.path.startsWith('$root/')) {
        final id = int.tryParse(uri.path.split('/').last);
        final matches = sessions.where((s) => s['id'] == id);
        if (matches.isNotEmpty) body = {'attendance_session': id == 60 ? detailSession ?? matches.single : matches.single,
          'records': id == 60 ? records : bySession[id] ?? <Map<String, dynamic>>[]};
      }
      if (body == null) return academic.get(path);
      return http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});
    }, post: (path, body) async {
      paths.add(path); posts.add(body); await beforeWrite?.call();
      final session = <String, dynamic>{...body, 'id': 61, 'status': 'open'};
      if (applyWrites && postStatus == 201) {
        sessions.add(session);
        bySession[61] = [for (final child in enrollments.where((e) => e['status'] == 'active' && e['section_id'] == body['section_id']))
          <String, dynamic>{'id': child['child_id'] + 100, 'attendance_session_id': 61,
            'child_id': child['child_id'], 'child_name': child['child_name'], 'status': 'present', 'note': null}];
      }
      afterWrite?.call();
      return http.Response(jsonEncode(createResponse ?? {'attendance_session': session,
        'students_initialized': bySession[61]?.length ?? 0}), postStatus);
    }, put: (path, body) async {
      paths.add(path); puts.add(body); await beforeWrite?.call();
      if (applyWrites && putStatus == 200) {
        final id = int.parse(path.split('/').reversed.elementAt(1));
        final rows = id == 60 ? records : bySession[id]!;
        for (final raw in body['records'] as List) {
          final mark = Map<String, dynamic>.from(raw as Map);
          final matches = rows.where((r) => r['child_id'] == mark['child_id']);
          if (matches.isNotEmpty) matches.single.addAll({'status': mark['status'], 'note': mark['note']});
        }
        if (body['close_session'] == true) sessions.singleWhere((s) => s['id'] == id)['status'] = 'closed';
      }
      afterWrite?.call();
      return http.Response(jsonEncode(saveResponse), putStatus);
    }),
  );
}
