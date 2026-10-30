/// Validate the existing ministry approval API receipt before showing success.
/// A pending request is not an approved educational plan.
bool ministrySubmissionReceiptMatches(
  Map<String, dynamic> receipt, {
  required int childId,
  required int evaluationId,
}) =>
    receipt['id'] is int &&
    (receipt['id'] as int) > 0 &&
    receipt['child_id'] == childId &&
    receipt['evaluation_id'] == evaluationId &&
    receipt['status'] == 'pending';
