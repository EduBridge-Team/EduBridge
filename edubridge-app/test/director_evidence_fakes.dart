import 'dart:async';
import 'dart:typed_data';

import 'package:edubridge_app/model/schools/director_evidence.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/director_evidence_repository.dart';

const evidenceDocument = DirectorDocument(
  id: 70,
  schoolId: 10,
  directorId: 30,
  kind: DirectorDocumentKind.identity,
  fileName: 'identity.pdf',
  sizeBytes: 8,
);
DirectorDocumentDraft evidenceDraft({String name = 'identity.pdf'}) =>
    DirectorDocumentDraft(
      kind: DirectorDocumentKind.identity,
      fileName: name,
      bytes: Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55]),
    );
DirectorEvidence evidenceState({
  DirectorVerificationStatus status = DirectorVerificationStatus.notSubmitted,
  bool withDocument = true,
}) => DirectorEvidence(
  documents: withDocument ? [evidenceDocument] : [],
  verification: DirectorVerification(
    status: status,
    requestId: status == DirectorVerificationStatus.notSubmitted ? null : 90,
    identityDocumentId: status == DirectorVerificationStatus.notSubmitted
        ? null
        : 70,
    reason: status == DirectorVerificationStatus.rejected
        ? 'Unreadable image'
        : null,
  ),
);

Map<String, dynamic> documentJson() => {
  'id': 70,
  'school_id': 10,
  'director_id': 30,
  'kind': 'identity',
  'file_name': 'identity.pdf',
  'size_bytes': 8,
};
Map<String, dynamic> verificationJson([String status = 'not_submitted']) => {
  'status': status,
  'request_id': status == 'not_submitted' ? null : 90,
  'identity_document_id': status == 'not_submitted' ? null : 70,
  'reason': status == 'rejected' ? 'Unreadable image' : null,
};
Map<String, dynamic> evidenceJson() => {
  'school_id': 10,
  'director_id': 30,
  'documents': [documentJson()],
  'verification': verificationJson(),
};

class FakeDirectorEvidence implements DirectorEvidenceGateway {
  DirectorEvidence state = evidenceState();
  DirectorFailure? loadFailure;
  DirectorFailure? writeFailure;
  bool failRefresh = false;
  Completer<void>? pendingWrite;
  Completer<DirectorEvidence>? pendingRead;
  int writes = 0;
  int links = 0;
  String? lastAction;
  @override
  Future<DirectorEvidence> load() async {
    if (loadFailure != null || (writes > 0 && failRefresh)) {
      throw DirectorApiException(loadFailure ?? DirectorFailure.network);
    }
    if (pendingRead != null) return pendingRead!.future;
    return state;
  }

  Future<void> _write(String action) async {
    writes++;
    lastAction = action;
    if (pendingWrite != null) await pendingWrite!.future;
    if (writeFailure != null) throw DirectorApiException(writeFailure!);
  }

  @override
  Future<void> upload(DirectorDocumentDraft draft) async {
    await _write('upload');
    state = evidenceState();
  }

  @override
  Future<void> remove(DirectorDocument document) async {
    await _write('remove');
    state = evidenceState(withDocument: false);
  }

  @override
  Future<void> submitVerification(int identityDocumentId) async {
    await _write('submit');
    state = evidenceState(status: DirectorVerificationStatus.pending);
  }

  @override
  Future<Uri> downloadLink(DirectorDocument document) async {
    links++;
    return Uri.parse('https://api.edubridge.win/signed-document');
  }
}
