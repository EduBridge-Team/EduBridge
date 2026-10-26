import '../../model/iep/iep_plan_history.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class IepHistoryGateway {
  Future<IepPlanHistory> load();
}

class IepHistoryRepository implements IepHistoryGateway {
  IepHistoryRepository({required this.childId, EnrollmentApiClient? client})
    : _client = client ?? EnrollmentApiClient();
  final int childId;
  final EnrollmentApiClient _client;
  @override
  Future<IepPlanHistory> load() async {
    if (childId < 1)
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    final data = await _client.get('/children/$childId/iep-plans');
    try {
      return IepPlanHistory.fromJson(childId, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
