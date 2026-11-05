import '../model/statistics/ministry_statistics.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class MinistryStatisticsGateway {
  Future<MinistryStatistics> load();
}

class MinistryStatisticsRepository implements MinistryStatisticsGateway {
  MinistryStatisticsRepository({EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  @override
  Future<MinistryStatistics> load() async {
    final data = await _client.get('/ministry/statistics');
    try {
      return MinistryStatistics.fromJson(data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
