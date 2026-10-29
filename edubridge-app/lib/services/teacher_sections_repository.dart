import '../model/schools/teacher_section.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class TeacherSectionsGateway {
  Future<TeacherSectionCatalog> sections();
  Future<TeacherSectionRoster> students(TeacherSection section);
}
class TeacherSectionsRepository implements TeacherSectionsGateway {
  TeacherSectionsRepository({EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  @override
  Future<TeacherSectionCatalog> sections() async {
    final data = await _client.get('/teachers/me/sections');
    try { return TeacherSectionCatalog.fromJson(data); }
    on FormatException { throw const EnrollmentApiException(EnrollmentFailure.invalidResponse); }
  }
  @override
  Future<TeacherSectionRoster> students(TeacherSection section) async {
    final data = await _client.get('/teachers/me/sections/${section.id}/students');
    try { return TeacherSectionRoster.fromJson(data, section); }
    on FormatException { throw const EnrollmentApiException(EnrollmentFailure.invalidResponse); }
  }
}
