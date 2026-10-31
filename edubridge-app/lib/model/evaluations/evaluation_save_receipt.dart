/// Verify a saved evaluation before presenting it as persisted or forwarding it
/// for approval. Older API responses omit child_id; a supplied one must match.
bool evaluationSaveReceiptMatchesChild(
  Map<String, dynamic> receipt,
  Object? requestedChildId,
) {
  final id = receipt['id'];
  return requestedChildId is int &&
      requestedChildId > 0 &&
      id is int &&
      id > 0 &&
      (!receipt.containsKey('child_id') ||
          receipt['child_id'] == requestedChildId);
}

/// A verified receipt may only be reused for the same child on a ministry retry.
bool evaluationRetryReceiptMatchesChild(
  Map<String, dynamic>? saved,
  int? savedChildId,
  Object? requestedChildId,
) => saved != null && savedChildId == requestedChildId &&
    evaluationSaveReceiptMatchesChild(saved, requestedChildId);
