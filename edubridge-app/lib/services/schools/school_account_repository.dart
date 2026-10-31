import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../model/schools/school_account.dart';
import '../api_service.dart';

enum SchoolAccountFailure {
  unavailable,
  unauthorized,
  forbidden,
  validation,
  conflict,
  rateLimited,
  network,
  uncertain,
  invalidResponse,
  server,
}

class SchoolAccountException implements Exception {
  const SchoolAccountException(this.failure, {this.fields = const {}});
  final SchoolAccountFailure failure;
  final Set<String> fields;
}

typedef SchoolAccountPost = Future<http.Response> Function(
  String path,
  Map<String, dynamic> body,
);
typedef SchoolAccountGet = Future<http.Response> Function(String path);

/// Flutter-owned API contract. No fallback to school-record CRUD endpoints.
class SchoolAccountRepository {
  SchoolAccountRepository({SchoolAccountPost? post, SchoolAccountGet? get})
    : _post = post ?? ApiService.authPost,
      _get = get ?? ApiService.authGet;

  final SchoolAccountPost _post;
  final SchoolAccountGet _get;
  static const _timeout = Duration(seconds: 30);

  Future<SchoolAccount> createIndependent(SchoolAccountRequest request) =>
      _create('/admin/school-accounts', request, organizationId: null);

  Future<SchoolAccount> createAffiliated(SchoolAccountRequest request) async {
    // Resolve the signed-in institution; never reuse another user's cached slug.
    final response = await _request(
      () => _get('/institutions/my-organization'),
    );
    _requireSuccess(response, 200);
    final organization = _decode(response.body)['organization'];
    if (organization is! Map<String, dynamic> ||
        organization['id'] is! int ||
        (organization['id'] as int) <= 0 ||
        organization['slug'] is! String ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{1,79}$')
            .hasMatch(organization['slug'] as String)) {
      throw const SchoolAccountException(SchoolAccountFailure.invalidResponse);
    }
    return _create(
      '/institutions/${organization['slug']}/school-accounts',
      request,
      organizationId: organization['id'] as int,
    );
  }

  Future<SchoolAccount> _create(
    String path,
    SchoolAccountRequest request, {
    required int? organizationId,
  }) async {
    final response = await _request(
      () => _post(path, request.toJson()),
      mutation: true,
    );
    _requireSuccess(response, 201);
    try {
      final account = SchoolAccount.fromJson(_decode(response.body));
      if (account.invitationPending != request.inviteDirector || account.organizationId != organizationId ||
          account.name.trim() != request.name.trim() ||
          account.email.toLowerCase() != request.email.trim().toLowerCase()) {
        throw const FormatException('Account scope mismatch');
      }
      return account;
    } on FormatException {
      throw const SchoolAccountException(SchoolAccountFailure.invalidResponse);
    }
  }

  Future<http.Response> _request(
    Future<http.Response> Function() send, {
    bool mutation = false,
  }) async {
    try {
      return await send().timeout(_timeout);
    } on TimeoutException {
      throw SchoolAccountException(
        mutation
            ? SchoolAccountFailure.uncertain
            : SchoolAccountFailure.network,
      );
    } on SocketException {
      throw SchoolAccountException(
        mutation
            ? SchoolAccountFailure.uncertain
            : SchoolAccountFailure.network,
      );
    } on http.ClientException {
      throw SchoolAccountException(
        mutation
            ? SchoolAccountFailure.uncertain
            : SchoolAccountFailure.network,
      );
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) return json;
    } on FormatException {
      // HTML and malformed responses are never treated as success.
    }
    throw const SchoolAccountException(SchoolAccountFailure.invalidResponse);
  }

  void _requireSuccess(http.Response response, int expected) {
    if (response.statusCode == expected) return;
    final failure = switch (response.statusCode) {
      401 => SchoolAccountFailure.unauthorized,
      403 => SchoolAccountFailure.forbidden,
      404 || 405 || 501 => SchoolAccountFailure.unavailable,
      409 => SchoolAccountFailure.conflict,
      422 => SchoolAccountFailure.validation,
      429 => SchoolAccountFailure.rateLimited,
      >= 200 && < 300 => SchoolAccountFailure.invalidResponse,
      _ => SchoolAccountFailure.server,
    };
    var fields = <String>{};
    if (failure == SchoolAccountFailure.validation) {
      try {
        final errors = _decode(response.body)['errors'];
        if (errors is Map<String, dynamic>) fields = errors.keys.toSet();
      } on SchoolAccountException {
        // A non-JSON validation response still receives the validation message.
      }
    }
    throw SchoolAccountException(failure, fields: fields);
  }
}
