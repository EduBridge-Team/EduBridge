import '../model/class_lessons/class_lesson_catalog.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class ClassLessonGateway {
  Future<ClassLessonCatalog> load();
}
/// Proposed authenticated teacher catalog. No inferred class or IEP associations.
class ClassLessonRepository implements ClassLessonGateway {
  ClassLessonRepository({EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  @override
  Future<ClassLessonCatalog> load() async {
    final data = await _client.get('/teachers/me/class-lessons');
    try { return ClassLessonCatalog.fromJson(data); }
    on FormatException { throw const EnrollmentApiException(EnrollmentFailure.invalidResponse); }
  }
}
