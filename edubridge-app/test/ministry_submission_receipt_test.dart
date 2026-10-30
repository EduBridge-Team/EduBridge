import 'package:edubridge_app/model/evaluations/ministry_submission_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acknowledges only child-scoped pending request for saved evaluation', () {
    expect(ministrySubmissionReceiptMatches({
      'id': 81, 'child_id': 6, 'evaluation_id': 21, 'status': 'pending',
    }, childId: 6, evaluationId: 21), isTrue);
  });

  for (final item in <Map<String, dynamic>>[
    {'id': 0, 'child_id': 6, 'evaluation_id': 21, 'status': 'pending'},
    {'id': 81, 'child_id': 7, 'evaluation_id': 21, 'status': 'pending'},
    {'id': 81, 'child_id': 6, 'evaluation_id': 22, 'status': 'pending'},
    {'id': 81, 'child_id': 6, 'evaluation_id': 21, 'status': 'approved'},
    {'id': 81, 'child_id': 6, 'evaluation_id': 21},
    {},
  ]) {
    test('refuses unverified or unrelated ministry receipt: $item', () {
      expect(ministrySubmissionReceiptMatches(item,
        childId: 6, evaluationId: 21), isFalse);
    });
  }
}
