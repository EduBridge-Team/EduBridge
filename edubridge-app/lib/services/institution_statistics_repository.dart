import '../model/enrollment/enrollment_models.dart';
import '../model/institutions/institution_statistics.dart';
import '../model/institutions/institution_timetable.dart';
import '../model/schools/academic_catalog.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class InstitutionStatisticsGateway {
  Future<InstitutionStatistics> load({DateTime? from, DateTime? to});
}
class InstitutionStatisticsRepository implements InstitutionStatisticsGateway {
  InstitutionStatisticsRepository({EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  Future<(int, String)> _context() async {
    final data = await _client.get('/institutions/my-organization');
    try {
      final row = enrollmentMap(data['organization']), id = enrollmentId(enrollmentMap(data['organization'])['id']);
      final slug = enrollmentText(row['slug']);
      if (!RegExp(r'^[a-z0-9][a-z0-9-]{1,79}$').hasMatch(slug)) throw const FormatException('Invalid institution');
      return (id, slug);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  @override
  Future<InstitutionStatistics> load({DateTime? from, DateTime? to}) async {
    from = from == null ? null : timetableDate(from); to = to == null ? null : timetableDate(to);
    if (from != null && to != null && to.isBefore(from)) throw const EnrollmentApiException(EnrollmentFailure.validation);
    final scope = await _context();
    final query = {if (from != null) 'from': academicDateText(from), if (to != null) 'to': academicDateText(to)};
    final path = '/institutions/${Uri.encodeComponent(scope.$2)}/management-report';
    final data = await _client.get(query.isEmpty ? path : '$path?${Uri(queryParameters: query).query}');
    if (await _context() != scope) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    try {
      return InstitutionStatistics.fromJson(scope.$1, scope.$2, data, from: from, to: to);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
