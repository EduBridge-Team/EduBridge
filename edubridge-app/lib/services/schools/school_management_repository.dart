import '../../model/schools/academic_catalog.dart';
import '../enrollment/enrollment_api_client.dart';
import 'academic_repository.dart';

class SchoolManagementRepository {
  SchoolManagementRepository({EnrollmentApiClient? client, this.expectedSchoolId}) : client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient client;
  final int? expectedSchoolId;
  SchoolManagementRepository scoped(int school) => SchoolManagementRepository(client: client, expectedSchoolId: school);

  Future<Map<String, dynamic>> context() async {
    final value = await client.get('/school/delegation');
    final school = value['school'];
    if (school is! Map || school['id'] is! int || (school['id'] as int) <= 0 ||
        school['name'] is! String || !['director', 'deputy_director', 'legacy_school'].contains(value['role']) ||
        value['permissions'] is! List) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    if (expectedSchoolId != null && school['id'] != expectedSchoolId) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    return value;
  }

  Future<Map<String, dynamic>> operation(String action, {Map<String, String> query = const {}}) async {
    final value = await client.get(Uri(path: '/school/operations/$action', queryParameters: query.isEmpty ? null : query).toString());
    if (expectedSchoolId != null && value['school_id'] != expectedSchoolId) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    return value;
  }

  Future<Map<String, dynamic>> mutate(String path, String method, Map<String, dynamic> body, {int success = 201}) {
    body = {...body, if (expectedSchoolId != null) 'expected_school_id': expectedSchoolId};
    return switch (method) {
    'PUT' => client.put(path, body),
    'PATCH' => client.patch(path, body),
    'DELETE' => client.delete(Uri(path: path, queryParameters: {for (final entry in body.entries) entry.key: '${entry.value}'}).toString()),
    _ => client.post(path, body, success: success),
    };
  }
}

class ManagedAcademicRepository implements AcademicGateway {
  ManagedAcademicRepository(this.repository);
  final SchoolManagementRepository repository;
  @override
  Future<AcademicCatalog> load() async {
    final context = await repository.context();
    final data = await repository.operation('academic');
    final normalized = {...data, 'sections': [for (final row in data['sections'] as List) {...Map<String,dynamic>.from(row as Map), 'school_id': data['school_id']}]};
    final result = AcademicCatalog.fromJson(normalized);
    if (result.school.id != (context['school'] as Map)['id']) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    return result;
  }
  @override
  Future<void> create(int schoolId, AcademicDraft draft) => AcademicRepository(client: repository.client).create(schoolId, draft);
}
