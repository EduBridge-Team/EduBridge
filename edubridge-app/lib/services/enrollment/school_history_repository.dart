import '../../model/enrollment/enrollment_models.dart';
import '../../model/enrollment/school_history.dart';
import 'enrollment_api_client.dart';

abstract interface class SchoolHistoryGateway {
  Future<SchoolHistory> load();
}

class SchoolHistoryRepository implements SchoolHistoryGateway {
  SchoolHistoryRepository({required this.childId, EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final int childId;
  final EnrollmentApiClient _client;

  @override
  Future<SchoolHistory> load() async {
    if (childId <= 0) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.get('/parent/children/$childId/school-history');
    try {
      enrollmentId(childId);
      return SchoolHistory.fromJson(data, childId);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
