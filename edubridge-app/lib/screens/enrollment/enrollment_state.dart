import 'package:flutter/foundation.dart';

import '../../services/enrollment/enrollment_api_client.dart';

/// Shared lifecycle for confirmed server writes followed by read-only refresh.
class EnrollmentState<T> extends ChangeNotifier {
  EnrollmentState(this._load);
  final Future<T> Function() _load;
  T? _snapshot;
  EnrollmentFailure? _error;
  bool _loading = false, _busy = false, _saved = false, _disposed = false;
  T? get snapshot => _snapshot;
  EnrollmentFailure? get error => _error;
  bool get loading => _loading;
  bool get busy => _busy;
  bool get saved => _saved;
  bool get canWrite => !_disposed && !_loading && !_busy && _snapshot != null;
  @protected
  bool get isAlive => !_disposed;
  @protected
  void emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> reload() async {
    if (_disposed || _loading || _busy) return;
    _loading = true;
    _error = null;
    _saved = false;
    emit();
    try {
      final data = await _load();
      if (!_disposed) _snapshot = data;
    } on EnrollmentApiException catch (e) {
      if (!_disposed) {
        _snapshot = null;
        _error = e.failure;
      }
    } finally {
      if (!_disposed) {
        _loading = false;
        emit();
      }
    }
  }

  @protected
  Future<void> mutate(Future<void> Function() action) async {
    if (!canWrite) return;
    _busy = true;
    _saved = false;
    _error = null;
    emit();
    var confirmed = false;
    try {
      await action();
      confirmed = true;
      if (_disposed) return;
      _saved = true;
      _snapshot = null;
      _snapshot = await _load();
    } on EnrollmentApiException catch (e) {
      if (!_disposed) {
        _error = e.failure;
        if (confirmed ||
            const {
              EnrollmentFailure.session,
              EnrollmentFailure.forbidden,
              EnrollmentFailure.unavailable,
              EnrollmentFailure.uncertain,
              EnrollmentFailure.invalidResponse,
              EnrollmentFailure.conflict,
              EnrollmentFailure.server,
            }.contains(e.failure)) {
          _snapshot = null;
        }
      }
    } finally {
      if (!_disposed) {
        _busy = false;
        emit();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
