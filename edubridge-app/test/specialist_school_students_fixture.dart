import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/specialist_school_students_repository.dart';

Map<String, dynamic> specialistCopy(Map<String, dynamic> data) =>
  jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
class SpecialistSchoolStudentsFixture {
  int userId = 7, status = 200;
  String role = 'specialist';
  bool badReceipt = false, failAfter = false, skipPersistence = false;
  Completer<void>? pending;
  void Function()? afterRoster;
  final paths = <String>[], posts = <Map<String, dynamic>>[];
  Map<String, dynamic> directory = specialistCopy({
    'contract_version': 1, 'complete': true, 'specialist_id': 7,
    'schools': [
      {'school_id': 2, 'organization_id': 4, 'assignment_id': 10, 'school_name': 'مدرسة الأمل'},
      {'school_id': 3, 'organization_id': 4, 'assignment_id': 11, 'school_name': 'مدرسة النور'},
    ],
  });
  final rosters = <int, Map<String, dynamic>>{};
  SpecialistSchoolStudentsFixture() {
    for (final id in [2, 3]) {
      rosters[id] = specialistCopy({
        'contract_version': 1, 'complete': true, 'specialist_id': 7, 'organization_id': 4,
        'school_id': id, 'assignment_id': id == 2 ? 10 : 11, 'revision': 'r1',
        'students': [
          {'child_id': id * 10, 'enrollment_id': id * 100, 'name': 'طالب $id',
            'section_id': id, 'section_name': 'شعبة $id', 'academic_year_id': 5,
            'academic_year_name': '2026 / 2027', 'is_following': false, 'followup_id': null, 'can_follow': true},
          {'child_id': id * 10 + 1, 'enrollment_id': id * 100 + 1, 'name': 'زميل $id',
            'section_id': id, 'section_name': 'شعبة $id', 'academic_year_id': 5,
            'academic_year_name': '2026 / 2027', 'is_following': true, 'followup_id': id * 1000, 'can_follow': false},
        ],
      });
    }
  }
  late final repository = SpecialistSchoolStudentsRepository(client: EnrollmentApiClient(get: (path) async {
    paths.add(path);
    Map<String, dynamic> data;
    var code = 200;
    if (path == '/me') data = {'user': {'id': userId, 'role': role}};
    else if (path == '/specialists/me/schools') { data = directory; code = status; }
    else if (path == '/specialists/me/schools/2/students' || path == '/specialists/me/schools/3/students') {
      final id = int.parse(path.split('/')[4]);
      data = specialistCopy(rosters[id]!); code = failAfter && posts.isNotEmpty ? 503 : status;
      afterRoster?.call();
    } else { throw StateError('Unexpected endpoint $path'); }
    return http.Response(jsonEncode(data), code, headers: {'content-type': 'application/json; charset=utf-8'});
  }, post: (path, body) async {
    paths.add(path); posts.add(Map.of(body));
    await pending?.future;
    final school = int.parse(path.split('/')[4]), child = int.parse(path.split('/')[6]);
    final roster = rosters[school]!;
    if (!skipPersistence) {
      final row = (roster['students'] as List).singleWhere((s) => s['child_id'] == child);
      row['is_following'] = true; row['can_follow'] = false; row['followup_id'] = 999;
      roster['revision'] = 'r2';
    }
    return http.Response(jsonEncode({
      'specialist_id': 7, 'organization_id': 4, 'school_id': badReceipt ? 9999 : school,
      'assignment_id': roster['assignment_id'], 'child_id': child,
      'enrollment_id': body['expected_enrollment_id'], 'followup_id': 999,
    }), 201, headers: {'content-type': 'application/json; charset=utf-8'});
  }));
}

