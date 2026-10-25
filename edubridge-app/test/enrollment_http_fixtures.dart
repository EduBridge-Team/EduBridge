import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:http/http.dart' as http;

import 'enrollment_fakes.dart';

http.Response enrollmentResponse(Object body, [int status = 200]) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Matches the existing parent endpoint payloads; no fake gateway bypasses parsing.
class ParentEnrollmentHttpFixture {
  List<Map<String, dynamic>> requests = [];
  Map<String, dynamic>? active;
  int reads = 0;
  final writes = <String>[];
  EnrollmentApiClient get client => EnrollmentApiClient(get: get, post: post);

  Future<http.Response> get(String path) async {
    if (path == '/parent/children/6/enrollment-requests') {
      reads++;
      return enrollmentResponse({
        'child_id': 6,
        'requests': requests,
        'active_enrollment': active,
      });
    }
    if (path == '/parent/enrollment-schools?q=School') {
      return enrollmentResponse({
        'schools': [
          {'id': 10, 'name': 'School A', 'address': 'Gaza'},
        ],
      });
    }
    throw StateError('Unexpected GET $path');
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    writes.add(path);
    if (path == '/parent/children/6/enrollment-requests') {
      if (jsonEncode(body) != jsonEncode({'school_id': 10}))
        throw StateError('Unexpected submission');
      requests = [enrollmentRequestJson()];
      return enrollmentResponse({'request': requests.single}, 201);
    }
    if (path == '/parent/children/6/enrollment-requests/50/cancel') {
      if (body['expected_version'] != 1)
        throw StateError('Missing optimistic version');
      requests = [enrollmentRequestJson(status: 'cancelled', version: 2)];
      return enrollmentResponse({'request': requests.single});
    }
    throw StateError('Unexpected POST $path');
  }
}

/// Exercises the documented school decision contract without changing the API.
class SchoolEnrollmentHttpFixture {
  List<Map<String, dynamic>> requests = [enrollmentRequestJson()];
  int inboxReads = 0;
  final decisions = <Map<String, dynamic>>[];
  EnrollmentApiClient get client => EnrollmentApiClient(get: get, post: post);

  Future<http.Response> get(String path) async {
    switch (path) {
      case '/school/context':
        return enrollmentResponse({
          'school': {'id': 10, 'name': 'School A', 'organization_id': null},
        });
      case '/school/enrollment-requests':
        inboxReads++;
        return enrollmentResponse({'school_id': 10, 'requests': requests});
      case '/school/enrollment-options':
        return enrollmentResponse({
          'school_id': 10,
          'sections': [
            {
              'id': 20,
              'name': 'A',
              'grade_name': 'Grade 2',
              'academic_year_id': 3,
              'academic_year_name': '2026/2027',
            },
          ],
        });
    }
    throw StateError('Unexpected GET $path');
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    if (path != '/school/enrollment-requests/50/decision')
      throw StateError('Unexpected POST $path');
    decisions.add(Map<String, dynamic>.from(body));
    final approved = body['decision'] == 'approved';
    final result = {
      ...enrollmentRequestJson(
        status: approved ? 'approved' : 'rejected',
        version: 2,
      ),
      'reason': body['reason'],
    };
    requests = [];
    return enrollmentResponse({
      'request': result,
      'enrollment': approved ? activeEnrollmentJson() : null,
    });
  }
}
