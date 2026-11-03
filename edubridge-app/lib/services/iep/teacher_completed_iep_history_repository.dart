import '../../model/enrollment/enrollment_models.dart';
import '../../model/iep/iep_plan_history.dart';
import '../../model/iep/iep_version.dart';
import '../enrollment/enrollment_api_client.dart';
import 'iep_history_repository.dart';

/// Teacher-specific read contract. Never substitute the specialist's full IEP
/// catalog or cached draft records when this authorized endpoint is unavailable.
class TeacherCompletedIepHistoryRepository implements IepHistoryGateway {
  TeacherCompletedIepHistoryRepository({
    required this.childId,
    EnrollmentApiClient? client,
  }) : _client = client ?? EnrollmentApiClient();

  final int childId;
  final EnrollmentApiClient _client;

  @override
  Future<IepPlanHistory> load() async {
    if (childId < 1) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.get('/teachers/me/children/$childId/completed-iep-plans');
    try {
      if (data['contract_version'] != 1 || data['complete'] != true ||
          enrollmentId(data['child_id']) != childId) {
        throw const FormatException('Unverified teacher plan catalog');
      }
      final catalog = IepPlanHistory.fromJson(childId, data);
      if (catalog.plans.any((plan) => plan.versions.isEmpty ||
          plan.versions.any((version) =>
              version.status != IepVersionStatus.completed))) {
        throw const FormatException('Teacher catalog contains an unpublished plan');
      }
      return catalog;
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
