import '../../model/evaluations/evaluation_record.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class EvaluationHistoryGateway {
  Future<EvaluationHistory> load();
}

class EvaluationHistoryRepository implements EvaluationHistoryGateway {
  EvaluationHistoryRepository({
    required this.childId,
    EnrollmentApiClient? client,
  }) : _client = client ?? EnrollmentApiClient();
  final int childId;
  final EnrollmentApiClient _client;
  @override
  Future<EvaluationHistory> load() async {
    if (childId < 1)
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    final data = await _client.get('/evaluations/child/$childId');
    try {
      return EvaluationHistory.fromJson(childId, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
