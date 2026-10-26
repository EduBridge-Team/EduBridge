import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_service.dart';

enum EnrollmentFailure {
  unavailable,
  session,
  forbidden,
  validation,
  conflict,
  rateLimited,
  network,
  uncertain,
  invalidResponse,
  server,
}

class EnrollmentApiException implements Exception {
  const EnrollmentApiException(this.failure);
  final EnrollmentFailure failure;
}

typedef EnrollmentGet = Future<http.Response> Function(String path);
typedef EnrollmentPost = Future<http.Response> Function(
  String path,
  Map<String, dynamic> body,
);

class EnrollmentApiClient {
  EnrollmentApiClient({EnrollmentGet? get, EnrollmentPost? post, EnrollmentPost? patch, EnrollmentPost? put, EnrollmentGet? delete})
    : _get = get ?? ApiService.authGet,
      _post = post ?? ApiService.authPost,
      _patch = patch ?? ApiService.authPatch,
      _put = put ?? ApiService.authPut,
      _delete = delete ?? ApiService.authDelete;
  final EnrollmentGet _get, _delete;
  final EnrollmentPost _post, _patch, _put;
  Future<Map<String, dynamic>> get(String path) => _send(() => _get(path), 200);
  Future<Map<String, dynamic>> delete(String path) =>
    _send(() => _delete(path), 200, mutation: true);
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    int success = 201,
  }) => _send(() => _post(path, body), success, mutation: true);
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) => _send(() => _patch(path, body), 200, mutation: true);

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
    _send(() => _put(path, body), 200, mutation: true);

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() send,
    int success, {
    bool mutation = false,
  }) async {
    late final http.Response response;
    try {
      response = await send().timeout(const Duration(seconds: 30));
    } on Exception {
      throw EnrollmentApiException(
        mutation ? EnrollmentFailure.uncertain : EnrollmentFailure.network,
      );
    }
    if (response.statusCode != success) {
      throw EnrollmentApiException(switch (response.statusCode) {
        401 => EnrollmentFailure.session,
        403 => EnrollmentFailure.forbidden,
        404 || 405 || 501 => EnrollmentFailure.unavailable,
        409 => EnrollmentFailure.conflict,
        422 => EnrollmentFailure.validation,
        429 => EnrollmentFailure.rateLimited,
        >= 200 && < 300 => EnrollmentFailure.invalidResponse,
        _ => EnrollmentFailure.server,
      });
    }
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // HTML or malformed success never confirms an operation.
    }
    throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
  }
}
