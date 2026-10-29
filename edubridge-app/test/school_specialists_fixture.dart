import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/school_specialist_assignments_repository.dart';

Map<String, dynamic> schoolSpecialistJson() => jsonDecode(jsonEncode({
  'contract_version': 1, 'complete': true, 'organization_id': 4, 'school_id': 2,
  'school_name': 'مدرسة الأمل', 'revision': 'r1', 'effective_on': '2026-10-29',
  'capabilities': {'can_assign': true},
  'eligible_specialists': [{'id': 7, 'name': 'أخصائي جديد'}, {'id': 8, 'name': 'أخصائي حالي'}],
  'assignments': [{'id': 10, 'specialist_id': 8, 'specialist_name': 'أخصائي حالي',
    'starts_on': '2026-09-01', 'ended_on': null, 'can_end': true}],
})) as Map<String, dynamic>;
class SchoolSpecialistsFixture {
  Map<String, dynamic> data = schoolSpecialistJson();
  final paths = <String>[], posts = <Map<String, dynamic>>[];
  int status = 200, postStatus = 0;
  bool badReceipt = false, failAfter = false, skipPersistence = false;
  Completer<void>? pending;
  late final repository = SchoolSpecialistAssignmentsRepository(
    organizationSlug: 'demo', organizationId: 4, schoolId: 2,
    client: EnrollmentApiClient(get: (path) async {
      paths.add(path);
      final code = failAfter && posts.isNotEmpty ? 503 : status;
      return http.Response(jsonEncode(data), code,
        headers: {'content-type': 'application/json; charset=utf-8'});
    }, post: (path, body) async {
      paths.add(path); posts.add(Map.of(body));
      await pending?.future;
      final ending = path.endsWith('/10/end');
      final record = ending ? {...(data['assignments'] as List).first as Map<String, dynamic>,
        'ended_on': '2026-10-29', 'can_end': false}
        : {'id': 11, 'specialist_id': body['specialist_id'], 'specialist_name': 'أخصائي جديد',
          'starts_on': '2026-10-29', 'ended_on': null, 'can_end': true};
      if (!skipPersistence) {
        if (ending) (data['assignments'] as List)[0] = record;
        else (data['assignments'] as List).add(record);
        data['revision'] = 'r2';
      }
      return http.Response(jsonEncode({'organization_id': 4,
        'school_id': badReceipt ? 999 : 2, 'assignment': record}), postStatus == 0 ? (ending ? 200 : 201) : postStatus,
        headers: {'content-type': 'application/json; charset=utf-8'});
    }));
}

