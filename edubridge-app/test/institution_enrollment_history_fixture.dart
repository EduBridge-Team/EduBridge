import 'dart:convert';

import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_enrollment_history_repository.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

class InstitutionHistoryFixture {
  final academic = InstitutionAcademicFixture();
  List<Map<String, dynamic>> rows = [
    {'id': 2, 'child_id': 9, 'child_name': 'نور', 'section_id': 30,
      'academic_year_id': 10, 'status': 'active', 'enrolled_on': '2026-10-01', 'left_on': null},
    {'id': 1, 'child_id': 8, 'child_name': 'أحمد', 'section_id': 30,
      'academic_year_id': 10, 'status': 'withdrawn', 'enrolled_on': '2026-09-01', 'left_on': '2026-09-30'},
  ];
  int status = 200;
  int? afterTransferReadStatus;
  int? afterWithdrawalReadStatus;
  int patchStatus = 200;
  Map<String, dynamic> patchResponse = {'updated': true};
  bool applyWithdrawal = true;
  Future<void> Function()? beforeWithdrawal;
  void Function()? afterWithdrawal;
  final patches = <Map<String, dynamic>>[];
  int postStatus = 201;
  Map<String, dynamic> postResponse = {'transferred': true};
  bool applyTransfer = true;
  final writes = <Map<String, dynamic>>[];
  void addTarget() {
    final sections = academic.data['sections'] as List;
    sections.add({...Map<String, dynamic>.from(sections.first as Map), 'id': 31, 'name': 'شعبة جديدة'});
  }
  final paths = <String>[];
  InstitutionEnrollmentHistoryRepository get repository => InstitutionEnrollmentHistoryRepository(
    organizationSlug: 'demo-institution', organizationId: 4, schoolId: 5,
    client: EnrollmentApiClient(get: (path) async {
      paths.add(path);
      if (path == '/institutions/demo-institution/schools/5/academic/student-enrollments') {
        return http.Response(jsonEncode({'enrollments': rows}),
          writes.isNotEmpty ? (afterTransferReadStatus ?? status) :
              patches.isNotEmpty ? (afterWithdrawalReadStatus ?? status) : status,
          headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return academic.get(path);
    }, patch: (path, body) async {
      paths.add(path);
      patches.add(body);
      await beforeWithdrawal?.call();
      if (applyWithdrawal && patchStatus == 200 && patchResponse['updated'] == true) {
        final row = rows.firstWhere((r) => r['id'] == 2);
        row['status'] = 'withdrawn';
        row['left_on'] = '2026-10-26';
      }
      afterWithdrawal?.call();
      return http.Response(jsonEncode(patchResponse), patchStatus);
    }, post: (path, body) async {
      paths.add(path);
      writes.add(body);
      if (applyTransfer && postStatus == 201 && postResponse['transferred'] == true) {
        final row = rows.firstWhere((r) => r['id'] == 2);
        row['status'] = 'transferred';
        row['left_on'] = '2026-10-26';
        rows.add({...row, 'id': 3, 'section_id': body['section_id'],
          'status': 'active', 'enrolled_on': '2026-10-26', 'left_on': null});
      }
      return http.Response(jsonEncode(postResponse), postStatus);
    }),
  );
}
