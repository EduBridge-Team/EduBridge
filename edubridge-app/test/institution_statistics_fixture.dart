import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_statistics_repository.dart';

class InstitutionStatisticsFixture {
  int status = 200, contextId = 4;
  bool changeContext = false;
  int contextReads = 0;
  final paths = <String>[];
  Future<void> Function()? beforeReport;
  Map<String, dynamic>? periodSummary;
  bool wrongPeriod = false;
  Map<String, dynamic> data = {
    'summary': {'schools': 1, 'student_files': 10, 'active_teachers': 2, 'active_enrollments': 5, 'attendance_sessions': 3},
    'schools': [<String, dynamic>{'school_id': 5, 'school_name': 'مدرسة الأمل', 'sections': 2,
      'active_enrollments': 5, 'timetable_entries': 4, 'attendance_sessions': 3,
      'attendance': {'present': 7, 'absent': 2, 'late': 1, 'excused': 0}}],
  };
  InstitutionStatisticsRepository get repository => InstitutionStatisticsRepository(client: EnrollmentApiClient(get: (path) async {
    paths.add(path);
    if (path == '/institutions/my-organization') {
      contextReads++;
      return http.Response(jsonEncode({'organization': {'id': changeContext && contextReads > 1 ? 99 : contextId,
        'slug': 'demo-institution'}}), 200);
    }
    await beforeReport?.call();
    final query = Uri.parse(path).queryParameters;
    final body = <String, dynamic>{...data,
      if (periodSummary != null && query.containsKey('from')) ...{
        'period': {'from': wrongPeriod ? '2026-01-01' : query['from'], 'to': query['to']},
        'period_summary': periodSummary,
      }};
    return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});
  }, post: (path, body) async => throw StateError('Read-only report')));
}
