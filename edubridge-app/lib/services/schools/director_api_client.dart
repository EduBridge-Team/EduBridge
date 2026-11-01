import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_service.dart';
import 'director_multipart_transport.dart';

enum DirectorFailure {
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
  invalidFile,
  openFailed,
}

class DirectorApiException implements Exception {
  const DirectorApiException(this.failure);
  final DirectorFailure failure;
}

typedef DirectorGet = Future<http.Response> Function(String path);
typedef DirectorWrite = Future<http.Response> Function(
  String path,
  Map<String, dynamic> body,
);

typedef DirectorMultipart = Future<http.Response> Function(
  String path,
  Map<String, String> fields,
  List<http.MultipartFile> files,
);

/// Transport and error normalization, independent of presentation state.
class DirectorApiClient {
  DirectorApiClient({
    DirectorGet? get,
    DirectorWrite? post,
    DirectorWrite? patch,
    DirectorGet? delete,
    DirectorMultipart? upload,
  }) : _get = get ?? ApiService.authGet,
       _post = post ?? ApiService.authPost,
       _patch = patch ?? ApiService.authPatch,
       _delete = delete ?? ApiService.authDelete,
       _upload = upload ?? DirectorMultipartTransport().upload;
  final DirectorGet _get;
  final DirectorWrite _post;
  final DirectorWrite _patch;
  final DirectorGet _delete;
  final DirectorMultipart _upload;

  Future<Map<String, dynamic>> delete(String path) =>
      _send(() => _delete(path), 200, mutation: true);
  Future<Map<String, dynamic>> upload(
    String path,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) => _send(() => _upload(path, fields, files), 201, mutation: true);

  Future<Map<String, dynamic>> get(String path) => _send(() => _get(path), 200);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data,
      {int expectedStatus = 201}) =>
      _send(() => _post(path, data), expectedStatus, mutation: true);
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) =>
      _send(() => _patch(path, data), 200, mutation: true);

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() send,
    int expected, {
    bool mutation = false,
  }) async {
    late final http.Response response;
    try {
      response = await send().timeout(const Duration(seconds: 30));
    } on Exception {
      // A lost write response can follow a committed operation. Never retry it.
      throw DirectorApiException(
        mutation ? DirectorFailure.uncertain : DirectorFailure.network,
      );
    }
    if (response.statusCode != expected) {
      throw DirectorApiException(switch (response.statusCode) {
        401 => DirectorFailure.session,
        403 => DirectorFailure.forbidden,
        404 || 405 || 501 => DirectorFailure.unavailable,
        409 => DirectorFailure.conflict,
        422 => DirectorFailure.validation,
        429 => DirectorFailure.rateLimited,
        >= 200 && < 300 => DirectorFailure.invalidResponse,
        _ => DirectorFailure.server,
      });
    }
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // Do not display arbitrary raw server errors or HTML.
    }
    throw const DirectorApiException(DirectorFailure.invalidResponse);
  }
}
