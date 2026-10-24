import 'dart:typed_data';

import 'school_director.dart';

enum DirectorDocumentKind { identity, qualification, appointment, other }

enum DirectorVerificationStatus { notSubmitted, pending, approved, rejected }

class DirectorDocumentDraft {
  DirectorDocumentDraft({
    required this.kind,
    required this.fileName,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes);
  static const maxBytes = 5 * 1024 * 1024;
  final DirectorDocumentKind kind;
  final String fileName;
  final Uint8List bytes;

  bool get isValid {
    if (bytes.isEmpty ||
        bytes.length > maxBytes ||
        fileName.length > 150 ||
        fileName.contains(RegExp(r'[\\/\r\n]')))
      return false;
    final extension = fileName.split('.').last.toLowerCase();
    bool starts(List<int> magic) =>
        bytes.length >= magic.length &&
        List.generate(
          magic.length,
          (i) => bytes[i] == magic[i],
        ).every((v) => v);
    return switch (extension) {
      'pdf' => starts([37, 80, 68, 70, 45]),
      'png' => starts([137, 80, 78, 71, 13, 10, 26, 10]),
      'jpg' || 'jpeg' => starts([255, 216, 255]),
      _ => false,
    };
  }
}

class DirectorDocument {
  const DirectorDocument({
    required this.id,
    required this.schoolId,
    required this.directorId,
    required this.kind,
    required this.fileName,
    required this.sizeBytes,
  });
  final int id;
  final int schoolId;
  final int directorId;
  final DirectorDocumentKind kind;
  final String fileName;
  final int sizeBytes;

  factory DirectorDocument.fromJson(Map<String, dynamic> data) {
    final kind = DirectorDocumentKind.values.where(
      (k) => k.name == data['kind'],
    );
    final size = data['size_bytes'];
    if (kind.length != 1 ||
        size is! int ||
        size <= 0 ||
        size > DirectorDocumentDraft.maxBytes) {
      throw const FormatException('Invalid document');
    }
    final fileName = directorText(data['file_name']);
    if (!const {
          'pdf',
          'jpg',
          'jpeg',
          'png',
        }.contains(fileName.split('.').last.toLowerCase()) ||
        fileName.length > 150 ||
        fileName.contains(RegExp(r'[\\/\r\n]'))) {
      throw const FormatException('Invalid file name');
    }
    return DirectorDocument(
      id: parseDirectorId(data['id']),
      schoolId: parseDirectorId(data['school_id']),
      directorId: parseDirectorId(data['director_id']),
      kind: kind.single,
      fileName: fileName,
      sizeBytes: size,
    );
  }
}

class DirectorVerification {
  const DirectorVerification({
    required this.status,
    this.requestId,
    this.identityDocumentId,
    this.reason,
  });
  final DirectorVerificationStatus status;
  final int? requestId;
  final int? identityDocumentId;
  final String? reason;
  bool get protectsIdentity =>
      status == DirectorVerificationStatus.pending ||
      status == DirectorVerificationStatus.approved;

  factory DirectorVerification.fromJson(Map<String, dynamic> data) {
    final status = switch (data['status']) {
      'not_submitted' => DirectorVerificationStatus.notSubmitted,
      'pending' => DirectorVerificationStatus.pending,
      'approved' => DirectorVerificationStatus.approved,
      'rejected' => DirectorVerificationStatus.rejected,
      _ => throw const FormatException('Invalid verification status'),
    };
    if (!data.containsKey('request_id') ||
        !data.containsKey('identity_document_id') ||
        (data['reason'] != null && data['reason'] is! String)) {
      throw const FormatException('Incomplete verification');
    }
    final requestId = data['request_id'] == null
        ? null
        : parseDirectorId(data['request_id']);
    final identityId = data['identity_document_id'] == null
        ? null
        : parseDirectorId(data['identity_document_id']);
    if (status == DirectorVerificationStatus.notSubmitted
        ? requestId != null || identityId != null
        : requestId == null || identityId == null) {
      throw const FormatException('Invalid verification references');
    }
    if (status == DirectorVerificationStatus.rejected &&
        (data['reason'] == null || (data['reason'] as String).trim().isEmpty)) {
      throw const FormatException('Rejection reason required');
    }
    return DirectorVerification(
      status: status,
      requestId: requestId,
      identityDocumentId: identityId,
      reason: data['reason'] as String?,
    );
  }
}

class DirectorEvidence {
  DirectorEvidence({
    required List<DirectorDocument> documents,
    required this.verification,
  }) : documents = List.unmodifiable(documents);
  final List<DirectorDocument> documents;
  final DirectorVerification verification;

  bool canRemove(DirectorDocument document) =>
      !verification.protectsIdentity ||
      verification.identityDocumentId != document.id;
}
