import '../../model/enrollment/enrollment_models.dart';
import '../../model/schools/promotion_roster.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class SchoolPromotionRosterGateway {
  Future<PromotionRoster> load({required int sourceYearId, required int targetYearId});
}

/// Proposed school-account API. Never use the institution-only Jabalia endpoints.
class SchoolPromotionRosterRepository implements SchoolPromotionRosterGateway {
  SchoolPromotionRosterRepository({EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;

  @override
  Future<PromotionRoster> load({required int sourceYearId, required int targetYearId}) async {
    if (sourceYearId <= 0 || targetYearId <= 0 || sourceYearId == targetYearId) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final context = await _client.get('/school/context');
    final data = await _client.get(
      '/school/annual-promotion/roster?source_year_id=$sourceYearId&target_year_id=$targetYearId',
    );
    try {
      final identity = SchoolPortalIdentity.fromJson(enrollmentMap(context['school']));
      return PromotionRoster.fromJson(data, schoolId: identity.school.id,
        sourceYearId: sourceYearId, targetYearId: targetYearId);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
