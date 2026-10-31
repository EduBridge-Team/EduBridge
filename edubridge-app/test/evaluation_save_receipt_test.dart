import 'package:edubridge_app/model/evaluations/evaluation_save_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ministry retry only reuses a verified receipt for the same child', () {
    expect(evaluationRetryReceiptMatchesChild({'id': 21}, 6, 6), isTrue);
    expect(evaluationRetryReceiptMatchesChild({'id': 21}, 6, 7), isFalse);
    expect(evaluationRetryReceiptMatchesChild({'id': 21, 'child_id': 7}, 6, 6), isFalse);
    expect(evaluationRetryReceiptMatchesChild(null, 6, 6), isFalse);
    expect(evaluationRetryReceiptMatchesChild({'id': 0}, 6, 6), isFalse);
    expect(evaluationRetryReceiptMatchesChild({'id': 21}, null, 6), isFalse);
  });

  test('accepts existing legacy receipt without child ID', () {
    expect(evaluationSaveReceiptMatchesChild({'id': 21}, 6), isTrue);
  });

  test('accepts matching child scope', () {
    expect(
      evaluationSaveReceiptMatchesChild({'id': 21, 'child_id': 6}, 6),
      isTrue,
    );
  });

  for (final receipt in <Map<String, dynamic>>[
    {},
    {'id': null},
    {'id': '21'},
    {'id': 0},
    {'id': -1},
    {'id': 21, 'child_id': 7},
    {'id': 21, 'child_id': null},
  ]) {
    test('rejects invalid or foreign evaluation save: $receipt', () {
      expect(evaluationSaveReceiptMatchesChild(receipt, 6), isFalse);
    });
  }

  test('rejects invalid requested child identifiers', () {
    expect(evaluationSaveReceiptMatchesChild({'id': 21}, null), isFalse);
    expect(evaluationSaveReceiptMatchesChild({'id': 21}, 0), isFalse);
    expect(evaluationSaveReceiptMatchesChild({'id': 21}, '6'), isFalse);
  });
}
