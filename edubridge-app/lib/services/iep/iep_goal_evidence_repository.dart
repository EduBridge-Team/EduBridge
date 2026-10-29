import '../../model/iep/iep_goal_evidence.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class IepGoalEvidenceGateway {
  Future<IepEvidenceHistory> load(IepEvidenceSource source);
}

/// Proposed read contract; unsupported servers display unavailable.
class IepGoalEvidenceRepository implements IepGoalEvidenceGateway {
  IepGoalEvidenceRepository({EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  @override
  Future<IepEvidenceHistory> load(IepEvidenceSource source) async {
    if (source.childId < 1 || source.planId < 1) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.get('/children/${source.childId}/iep-plans/'
        '${source.planId}/versions/${source.goal.versionId}/goals/${source.goal.id}/evidence');
    try {
      return IepEvidenceHistory.fromJson(source, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}

