import '../../model/enrollment/enrollment_models.dart';
import '../../model/schools/promotion_roster.dart';
import '../enrollment/enrollment_api_client.dart';

/// Server-authoritative receipt. A local preview is never an approval.
class SchoolPromotionReceipt {
  const SchoolPromotionReceipt({required this.operationId, required this.schoolId,
    required this.sourceYearId, required this.targetYearId, required this.status,
    required this.promoted, required this.repeating, required this.transferred});
  final String operationId, status;
  final int schoolId, sourceYearId, targetYearId, promoted, repeating, transferred;
  bool get completed => status == 'completed';

  factory SchoolPromotionReceipt.fromJson(Map<String, dynamic> value,
      {required int schoolId}) {
    final counts = enrollmentMap(value['counts']);
    final operationId = enrollmentText(value['operation_id']);
    final status = enrollmentText(value['status']);
    final source = enrollmentId(value['source_year_id']);
    final target = enrollmentId(value['target_year_id']);
    int count(String key) {
      final value = counts[key];
      if (value is! int || value < 0) throw const FormatException('Invalid count');
      return value;
    }
    final promoted = count('promoted');
    final repeating = count('repeating');
    final transferred = count('transferred');
    if (enrollmentId(value['school_id']) != schoolId ||
        operationId.isEmpty || source <= 0 || target <= 0 || target == source ||
        !['completed', 'pending', 'failed'].contains(status) ||
        promoted < 0 || repeating < 0 || transferred < 0) {
      throw const FormatException('Invalid school promotion receipt');
    }
    return SchoolPromotionReceipt(operationId: operationId, schoolId: schoolId,
      sourceYearId: source, targetYearId: target, status: status,
      promoted: promoted, repeating: repeating, transferred: transferred);
  }
}

class SchoolPromotionServerPreview {
  const SchoolPromotionServerPreview(this.token, this.revision, this.schoolId,
    this.sourceYearId, this.targetYearId, this.ready);
  final String token, revision;
  final int schoolId, sourceYearId, targetYearId;
  final bool ready;

  factory SchoolPromotionServerPreview.fromJson(Map<String, dynamic> value,
      PromotionDraft draft) {
    final errors = enrollmentList(value['blocking_errors']);
    final token = enrollmentText(value['preview_token']);
    final revision = enrollmentText(value['roster_revision']);
    final ready = value['ready'] == true && errors.isEmpty &&
        token.isNotEmpty && revision == draft.roster.revision &&
        enrollmentId(value['school_id']) == draft.roster.schoolId &&
        enrollmentId(value['source_year_id']) == draft.roster.sourceYearId &&
        enrollmentId(value['target_year_id']) == draft.roster.targetYearId;
    if (!ready) throw const FormatException('Server preview not ready');
    return SchoolPromotionServerPreview(token, revision, draft.roster.schoolId,
      draft.roster.sourceYearId, draft.roster.targetYearId, true);
  }
}

abstract interface class SchoolPromotionOperationGateway {
  Future<SchoolPromotionServerPreview> preview(PromotionDraft draft);
  Future<SchoolPromotionReceipt> approve(PromotionDraft draft,
      SchoolPromotionServerPreview preview, String idempotencyKey);
  Future<SchoolPromotionReceipt> operation(String operationId, {required int schoolId});
  Future<List<SchoolPromotionReceipt>> history({required int yearId, required int schoolId});
}

/// Uses server previews, atomic approval and idempotent operation recovery.
class SchoolPromotionOperationRepository implements SchoolPromotionOperationGateway {
  SchoolPromotionOperationRepository({EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;

  @override
  Future<SchoolPromotionServerPreview> preview(PromotionDraft draft) async {
    if (!draft.ready) throw const EnrollmentApiException(EnrollmentFailure.validation);
    final result = await _client.post('/school/annual-promotion/preview',
      draft.previewJson(), success: 200);
    try {
      return SchoolPromotionServerPreview.fromJson(result, draft);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<SchoolPromotionReceipt> approve(PromotionDraft draft,
      SchoolPromotionServerPreview preview, String idempotencyKey) async {
    if (!draft.ready || !preview.ready ||
        preview.schoolId != draft.roster.schoolId ||
        preview.revision != draft.roster.revision ||
        preview.sourceYearId != draft.roster.sourceYearId ||
        preview.targetYearId != draft.roster.targetYearId ||
        idempotencyKey.isEmpty) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final result = await _client.post('/school/annual-promotion/approve', {
      ...draft.previewJson(), 'preview_token': preview.token,
      'idempotency_key': idempotencyKey,
    }, success: 200);
    try {
      final receipt = SchoolPromotionReceipt.fromJson(result, schoolId: draft.roster.schoolId);
      if (receipt.sourceYearId != draft.roster.sourceYearId ||
          receipt.targetYearId != draft.roster.targetYearId ||
          receipt.promoted + receipt.repeating + receipt.transferred != draft.roster.students.length) {
        throw const FormatException('Unverified promotion counts');
      }
      return receipt;
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<SchoolPromotionReceipt> operation(String operationId, {required int schoolId}) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(operationId)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final result = await _client.get('/school/annual-promotion/operations/$operationId');
    try {
      final receipt = SchoolPromotionReceipt.fromJson(result, schoolId: schoolId);
      if (receipt.operationId != operationId) throw const FormatException('Mismatched operation');
      return receipt;
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<List<SchoolPromotionReceipt>> history({required int yearId, required int schoolId}) async {
    if (yearId <= 0 || schoolId <= 0) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final result = await _client.get('/school/annual-promotion/history?year_id=$yearId');
    try {
      if (enrollmentId(result['school_id']) != schoolId || result['complete'] != true) {
        throw const FormatException('Incomplete promotion history');
      }
      final operations = enrollmentList(result['operations']).map((value) =>
        SchoolPromotionReceipt.fromJson(enrollmentMap(value), schoolId: schoolId)).toList();
      // A complete history must only include the selected source year,
      // with unique operation IDs. Never display records from another year.
      if (operations.any((item) => item.sourceYearId != yearId) ||
          operations.map((item) => item.operationId).toSet().length != operations.length) {
        throw const FormatException('Foreign or duplicate promotion history');
      }
      return List<SchoolPromotionReceipt>.unmodifiable(operations);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
