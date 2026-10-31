part of 'api_service.dart';

/// School-local identities: never cache passwords or expose them in logs.
Future<Map<String, dynamic>> _apiSchoolInternalAccountsList({
  int? afterId,
  int limit = 50,
  String? role,
}) async {
  if (limit < 1 || limit > 100) {
    throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 100');
  }
  if (role != null && role != 'teacher' && role != 'student') {
    throw ArgumentError.value(role, 'role', 'Invalid school account role');
  }
  final query = <String, String>{'limit': '$limit'};
  if (afterId != null) query['after_id'] = '$afterId';
  if (role != null) query['role'] = role;
  final uri = Uri(path: '/school/internal-identities', queryParameters: query);
  final response = await ApiService.authGet(
    '${uri.path}?${uri.query}',
  );
  final body = ApiService.decodeMap(response.body);
  if (response.statusCode != 200) {
    throw Exception(body['error'] ?? 'تعذر تحميل الحسابات الداخلية');
  }
  return body;
}

Future<Map<String, dynamic>> _apiSchoolInternalAccountCreate({
  required String name,
  required String username,
  required String role,
  required String password,
}) async {
  if (role != 'teacher' && role != 'student') {
    throw ArgumentError.value(role, 'role', 'Invalid school account role');
  }
  final response = await ApiService.authPost('/school/internal-identities', {
    'name': name.trim(),
    'username': username.trim(),
    'role': role,
    'password': password,
  });
  final body = ApiService.decodeMap(response.body);
  if (response.statusCode != 201) {
    throw Exception(body['error'] ?? 'تعذر إنشاء الحساب الداخلي');
  }
  return body;
}
