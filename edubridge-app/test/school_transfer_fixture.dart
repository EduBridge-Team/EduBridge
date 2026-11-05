import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/school_management_repository.dart';
import 'package:edubridge_app/services/transfers/school_transfer_repository.dart';

class SchoolTransferFixture {
  int school = 5, postStatus = 201;
  bool allowed = true, changedScope = false;
  final writes = <(String, Map<String, dynamic>)>[];
  Map<String, dynamic>? receipt;
  List<dynamic> enrollments = [
    {
      'id': 10,
      'child_id': 30,
      'child_name': 'Student',
      'section_name': 'Section A',
      'status': 'active'
    }
  ];
  List<dynamic> schools = [
    {'id': 9, 'name': 'Destination School'}
  ];
  List<dynamic> sections = [
    {
      'id': 21,
      'name': 'Section B',
      'grade_name': 'Grade 2',
      'academic_year_name': '2026'
    }
  ];
  List<dynamic> incoming = [
    {
      'id': 40,
      'child_id': 31,
      'source_school_id': 9,
      'destination_school_id': 5,
      'status': 'pending_destination',
      'version': 2
    }
  ];
  late final repository = SchoolTransferRepository(
      schoolId: 5,
      repository: SchoolManagementRepository(
          client: EnrollmentApiClient(
        get: (path) async {
          final data = switch (path) {
            '/school/delegation' => {
                'school': {'id': changedScope ? 6 : school, 'name': 'School'},
                'role': 'director',
                'permissions': [if (allowed) 'enrollment']
              },
            '/school/operations/students' => {
                'school_id': school,
                'enrollments': enrollments
              },
            '/school/operations/academic' => {
                'school_id': school,
                'school': {'id': school},
                'sections': sections
              },
            '/school/annual-promotion/transfer-schools' => {'schools': schools},
            '/school/transfers/incoming' => {'requests': incoming},
            _ => throw StateError(path),
          };
          return http.Response(jsonEncode(data), 200);
        },
        post: (path, body) async {
          writes.add((path, body));
          return http.Response(
              jsonEncode(receipt ??
                  (path == '/school/transfers'
                      ? {'request_id': 50, 'status': 'pending_guardian'}
                      : {
                          'request_id': 40,
                          'status': body['decision'] == 'accept'
                              ? 'completed'
                              : 'destination_rejected',
                          if (body['decision'] == 'accept') 'enrollment_id': 60
                        })),
              postStatus);
        },
      )));
}
