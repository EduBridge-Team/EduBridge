import 'dart:convert';

import 'package:edubridge_app/model/schools/promotion_roster.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/school_promotion_operation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

PromotionDraft draft() {
  final roster = PromotionRoster.fromJson({
    'school_id': 5, 'source_year_id': 10, 'target_year_id': 11,
    'complete': true, 'revision': 'rev-1',
    'students': [
      {'enrollment_id': 101, 'child_id': 201, 'child_name': 'Sara',
        'source_grade_id': 20, 'source_section_id': 30},
    ],
    'target_sections': [
      {'id': 31, 'grade_id': 21, 'name': 'Third A',
        'capacity': 10, 'occupied': 0},
    ],
  }, schoolId: 5, sourceYearId: 10, targetYearId: 11);
  return PromotionDraft(roster, {
    101: const PromotionSelection(101, PromotionOutcome.promoted, 31),
  });
}

Map<String, dynamic> previewJson({int schoolId = 5}) => {
  'school_id': schoolId, 'source_year_id': 10, 'target_year_id': 11,
  'roster_revision': 'rev-1', 'preview_token': 'token',
  'ready': true, 'blocking_errors': [],
};

Map<String, dynamic> receiptJson({int schoolId = 5, String status = 'completed'}) => {
  'operation_id': 'op_1', 'school_id': schoolId,
  'source_year_id': 10, 'target_year_id': 11, 'status': status,
  'counts': {'promoted': 1, 'repeating': 0, 'transferred': 0},
};

void main() {
  test('server preview checks school, years and revision', () {
    expect(SchoolPromotionServerPreview.fromJson(previewJson(), draft()).ready, isTrue);
    expect(() => SchoolPromotionServerPreview.fromJson(previewJson(schoolId: 8),
      draft()), throwsFormatException);
    expect(() => SchoolPromotionServerPreview.fromJson({
      ...previewJson(), 'roster_revision': 'stale',
    }, draft()), throwsFormatException);
    expect(() => SchoolPromotionServerPreview.fromJson({
      ...previewJson(), 'blocking_errors': ['no seats'],
    }, draft()), throwsFormatException);
  });

  test('approval sends exact draft once and confirms authoritative receipt', () async {
    final writes = <Map<String, dynamic>>[];
    final client = EnrollmentApiClient(
      post: (path, body) async {
        writes.add({'path': path, 'body': body});
        return http.Response(jsonEncode(path.endsWith('/preview') ?
          previewJson() : receiptJson()), 200);
      },
    );
    final repository = SchoolPromotionOperationRepository(client: client);
    final selection = draft();
    final preview = await repository.preview(selection);
    final receipt = await repository.approve(selection, preview, 'request-1');
    expect(receipt.completed, isTrue);
    expect(writes, hasLength(2));
    expect(writes[1]['path'], '/school/annual-promotion/approve');
    expect((writes[1]['body'] as Map)['idempotency_key'], 'request-1');
  });

  test('foreign school receipt is rejected rather than marked completed', () async {
    final repository = SchoolPromotionOperationRepository(client: EnrollmentApiClient(
      post: (path, body) async => http.Response(jsonEncode(
        path.endsWith('/preview') ? previewJson() : receiptJson(schoolId: 9)), 200),
    ));
    final selection = draft();
    final preview = await repository.preview(selection);
    await expectLater(repository.approve(selection, preview, 'request-2'),
      throwsA(isA<EnrollmentApiException>().having(
        (value) => value.failure, 'failure', EnrollmentFailure.invalidResponse)));
  });

  test('history requires complete school scoped data', () async {
    final repository = SchoolPromotionOperationRepository(client: EnrollmentApiClient(
      get: (path) async => http.Response(jsonEncode({
        'school_id': 5, 'complete': false, 'operations': [receiptJson()],
      }), 200),
    ));
    await expectLater(repository.history(yearId: 10, schoolId: 5),
      throwsA(isA<EnrollmentApiException>().having(
        (value) => value.failure, 'failure', EnrollmentFailure.invalidResponse)));
  });
}
