import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../model/schools/director_evidence.dart';
import '../../model/schools/school_director.dart';
import 'director_api_client.dart';

abstract interface class DirectorEvidenceGateway {
  Future<DirectorEvidence> load();
  Future<void> upload(DirectorDocumentDraft draft);
  Future<void> remove(DirectorDocument document);
  Future<void> submitVerification(int identityDocumentId);
  Future<Uri> downloadLink(DirectorDocument document);
}

class DirectorEvidenceRepository implements DirectorEvidenceGateway {
  DirectorEvidenceRepository({
    required this.school,
    required this.directorId,
    DirectorApiClient? client,
    DateTime Function()? clock,
  }) : _client = client ?? DirectorApiClient(),
       _clock = clock ?? DateTime.now;
  final DirectorSchool school;
  final int directorId;
  final DirectorApiClient _client;
  final DateTime Function() _clock;
  String get _path => '${school.path}/directors/$directorId';

  T _parse<T>(T Function() read) {
    try {
      return read();
    } on FormatException {
      throw const DirectorApiException(DirectorFailure.invalidResponse);
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map<String, dynamic>)
      throw const FormatException('Expected object');
    return value;
  }

  void _scope(Map<String, dynamic> data) {
    if (parseDirectorId(data['school_id']) != school.id ||
        parseDirectorId(data['director_id']) != directorId) {
      throw const FormatException('Evidence scope mismatch');
    }
  }

  DirectorDocument _document(dynamic value) {
    final data = _map(value);
    _scope(data);
    return DirectorDocument.fromJson(data);
  }

  @override
  Future<DirectorEvidence> load() async {
    final data = await _client.get('$_path/evidence');
    return _parse(() {
      _scope(data);
      if (data['documents'] is! List)
        throw const FormatException('Missing documents');
      final documents = (data['documents'] as List).map(_document).toList();
      final verification = DirectorVerification.fromJson(
        _map(data['verification']),
      );
      if (documents.map((d) => d.id).toSet().length != documents.length ||
          (verification.protectsIdentity &&
              !documents.any(
                (d) =>
                    d.id == verification.identityDocumentId &&
                    d.kind == DirectorDocumentKind.identity,
              ))) {
        throw const FormatException('Invalid evidence references');
      }
      return DirectorEvidence(documents: documents, verification: verification);
    });
  }

  @override
  Future<void> upload(DirectorDocumentDraft draft) async {
    if (!draft.isValid)
      throw const DirectorApiException(DirectorFailure.invalidFile);
    final data = await _client.upload(
      '$_path/documents',
      {'kind': draft.kind.name},
      [
        http.MultipartFile.fromBytes(
          'file',
          draft.bytes,
          filename: draft.fileName,
        ),
      ],
    );
    _parse(() {
      final result = _document(data['document']);
      if (result.kind != draft.kind ||
          result.fileName != draft.fileName ||
          result.sizeBytes != draft.bytes.length)
        throw const FormatException('Upload mismatch');
    });
  }

  @override
  Future<void> remove(DirectorDocument document) async {
    if (document.schoolId != school.id || document.directorId != directorId) {
      throw const DirectorApiException(DirectorFailure.forbidden);
    }
    final data = await _client.delete('$_path/documents/${document.id}');
    _parse(() {
      _scope(data);
      if (data['document_id'] != document.id || data['deleted'] != true) {
        throw const FormatException('Deletion not confirmed');
      }
    });
  }

  @override
  Future<void> submitVerification(int identityDocumentId) async {
    final data = await _client.post('$_path/verification', {
      'identity_document_id': identityDocumentId,
    });
    _parse(() {
      _scope(data);
      final result = DirectorVerification.fromJson(_map(data['verification']));
      if (result.status != DirectorVerificationStatus.pending ||
          result.identityDocumentId != identityDocumentId) {
        throw const FormatException('Submission not confirmed');
      }
    });
  }

  @override
  Future<Uri> downloadLink(DirectorDocument document) async {
    if (document.schoolId != school.id || document.directorId != directorId) {
      throw const DirectorApiException(DirectorFailure.forbidden);
    }
    final data = await _client.get(
      '$_path/documents/${document.id}/download-link',
    );
    return _parse(() {
      _scope(data);
      final uri = data['url'] is String
          ? Uri.tryParse(data['url'] as String)
          : null;
      final expiry = data['expires_at'] is String
          ? DateTime.tryParse(data['expires_at'] as String)
          : null;
      final api = Uri.parse(Config.baseUrl);
      final now = _clock();
      if (data['document_id'] != document.id ||
          uri == null ||
          expiry == null ||
          uri.scheme != 'https' ||
          uri.host != api.host ||
          uri.port != api.port ||
          uri.userInfo.isNotEmpty ||
          uri.fragment.isNotEmpty ||
          uri.path != '${api.path}$_path/documents/${document.id}/content' ||
          (uri.queryParameters['signature'] ?? '').isEmpty ||
          !expiry.isUtc ||
          int.tryParse(uri.queryParameters['expires'] ?? '') !=
              expiry.millisecondsSinceEpoch ~/ 1000 ||
          uri.queryParametersAll.values.any((values) => values.length != 1) ||
          uri.queryParameters.keys.any(
            (k) => !const {'signature', 'expires'}.contains(k),
          ) ||
          !expiry.isAfter(now) ||
          expiry.difference(now) > const Duration(minutes: 5)) {
        throw const FormatException('Unsafe or expired download link');
      }
      return uri;
    });
  }
}
