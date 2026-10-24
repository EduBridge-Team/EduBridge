import 'package:flutter/foundation.dart';

import '../../../model/schools/director_evidence.dart';
import '../../../services/schools/director_api_client.dart';
import '../../../services/schools/director_evidence_repository.dart';

typedef DirectorEvidencePick = Future<DirectorDocumentDraft?> Function(
  DirectorDocumentKind kind,
);

class DirectorEvidenceController extends ChangeNotifier {
  DirectorEvidenceController(this._gateway);
  final DirectorEvidenceGateway _gateway;
  DirectorEvidence? _evidence;
  DirectorFailure? _error;
  bool _loading = false;
  bool _busy = false;
  bool _saved = false;
  bool _disposed = false;
  DirectorEvidence? get evidence => _evidence;
  DirectorFailure? get error => _error;
  bool get loading => _loading;
  bool get busy => _busy;
  bool get saved => _saved;
  bool get canWrite => !_disposed && !_loading && !_busy && _evidence != null;

  Future<void> reload() async {
    if (_disposed || _loading || _busy) return;
    _loading = true;
    _error = null;
    _saved = false;
    _emit();
    try {
      final result = await _gateway.load();
      if (!_disposed) _evidence = result;
    } on DirectorApiException catch (error) {
      if (!_disposed) {
        _error = error.failure;
        _evidence = null;
      }
    } finally {
      if (!_disposed) {
        _loading = false;
        _emit();
      }
    }
  }

  Future<void> pickAndUpload(
    DirectorDocumentKind kind,
    DirectorEvidencePick picker,
  ) => _write(() async {
    final draft = await picker(kind);
    if (draft == null || _disposed) return false;
    if (!draft.isValid || draft.kind != kind) {
      throw const DirectorApiException(DirectorFailure.invalidFile);
    }
    await _gateway.upload(draft);
    return true;
  });

  Future<void> remove(DirectorDocument document) async {
    if (!canWrite ||
        !_evidence!.documents.contains(document) ||
        !_evidence!.canRemove(document))
      return;
    await _write(() async {
      await _gateway.remove(document);
      return true;
    });
  }

  Future<void> submit(int identityDocumentId) async {
    if (!canWrite ||
        _evidence!.verification.status == DirectorVerificationStatus.pending ||
        !_evidence!.documents.any(
          (d) =>
              d.id == identityDocumentId &&
              d.kind == DirectorDocumentKind.identity,
        ))
      return;
    if (_evidence!.verification.status == DirectorVerificationStatus.approved &&
        _evidence!.verification.identityDocumentId == identityDocumentId)
      return;
    await _write(() async {
      await _gateway.submitVerification(identityDocumentId);
      return true;
    });
  }

  Future<void> _write(Future<bool> Function() operation) async {
    if (!canWrite) return;
    _busy = true;
    _error = null;
    _saved = false;
    _emit();
    var confirmed = false;
    try {
      confirmed = await operation();
      if (_disposed || !confirmed) return;
      _saved = true;
      _evidence = null;
      _evidence = await _gateway.load();
    } on DirectorApiException catch (error) {
      if (!_disposed) {
        _error = error.failure;
        if (confirmed ||
            const {
              DirectorFailure.uncertain,
              DirectorFailure.invalidResponse,
              DirectorFailure.conflict,
              DirectorFailure.server,
            }.contains(error.failure))
          _evidence = null;
      }
    } finally {
      if (!_disposed) {
        _busy = false;
        _emit();
      }
    }
  }

  Future<void> open(
    DirectorDocument document,
    Future<bool> Function(Uri) launch,
  ) async {
    if (!canWrite || !_evidence!.documents.contains(document)) return;
    _busy = true;
    _error = null;
    _emit();
    try {
      final uri = await _gateway.downloadLink(document);
      if (!_disposed && !await launch(uri) && !_disposed)
        _error = DirectorFailure.openFailed;
    } on Exception {
      if (!_disposed) _error = DirectorFailure.openFailed;
    } finally {
      if (!_disposed) {
        _busy = false;
        _emit();
      }
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
