import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';
import '../domain/student_profile.dart';

class StudentProfileRepository {
  StudentProfileRepository({Future<http.Response> Function(String)? get})
      : _get = get ?? ApiService.authGet;
  final Future<http.Response> Function(String) _get;

  Future<StudentProfile> load(int childId, {bool allowAssignmentPreview = false}) async {
    var response = await _get('/children/$childId');
    // Only the specialist caller opts into the existing preview endpoint.
    if (response.statusCode == 403 && allowAssignmentPreview) {
      response = await _get('/children/$childId/assignment-preview');
    }
    final data = ApiService.decodeMap(response.body);
    if (response.statusCode != 200 || data['child'] is! Map) {
      throw const StudentProfileLoadException();
    }
    return StudentProfile.fromJson(Map<String, dynamic>.from(data['child'] as Map));
  }
}

class StudentProfileLoadException implements Exception {
  const StudentProfileLoadException();
  @override
  String toString() => 'تعذّر تحميل معلومات الطالب';
}
