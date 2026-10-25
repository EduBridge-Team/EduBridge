import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Institution school requests and response decoding; no widget state or UI.
class InstitutionSchoolRepository {
  String _path(String slug, String endpoint) =>
      '/institutions/${Uri.encodeComponent(slug)}$endpoint';

  Map<String, dynamic> _decode(http.Response response, String failureMessage) {
    final data = ApiService.decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? data['message'] ?? failureMessage);
    }
    return data;
  }

  Future<String> resolveOrganization({required String failureMessage}) async {
    final response = await ApiService.authGet('/institutions/my-organization');
    final organization = ApiService.decodeMap(response.body)['organization'];
    if (response.statusCode != 200 || organization is! Map) {
      throw Exception(failureMessage);
    }
    final slug = organization['slug'];
    if (organization['id'] is! int ||
        organization['id'] <= 0 ||
        slug is! String ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{1,79}$').hasMatch(slug)) {
      throw const FormatException('Invalid institution context');
    }
    return slug;
  }

  Future<Map<String, dynamic>> _get(String slug, String endpoint) async {
    final response = await ApiService.authGet(_path(slug, endpoint));
    return _decode(
      response,
      'تعذّر تحميل البيانات (HTTP ${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> loadReport(String slug) =>
      _get(slug, '/management-report');

  Future<List<Map<String, dynamic>>> loadSchools(String slug) async {
    final data = (await _get(slug, '/schools'))['schools'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> loadSchool(String slug, int schoolId) async {
    final response = await ApiService.authGet(
      _path(slug, '/schools/$schoolId'),
    );
    return _decode(response, 'تعذّر تحميل بيانات المدرسة');
  }

  Future<void> createSchool(String slug, Map<String, String> fields) async {
    final response = await ApiService.authPost(_path(slug, '/schools'), fields);
    _decode(response, 'تعذّر إضافة المدرسة');
  }

  Future<void> updateSchool(
    String slug,
    int schoolId,
    Map<String, String> fields,
  ) async {
    final response = await ApiService.authPatch(
      _path(slug, '/schools/$schoolId'),
      fields,
    );
    _decode(response, 'تعذر حفظ المدرسة (HTTP ${response.statusCode})');
  }
}
