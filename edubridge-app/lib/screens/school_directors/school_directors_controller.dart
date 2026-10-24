import 'package:flutter/foundation.dart';

import '../../model/schools/school_director.dart';
import '../../services/schools/director_api_client.dart';
import '../../services/schools/school_director_repository.dart';

/// Owns async lifecycle and serializes mutations; widgets only collect input.
class SchoolDirectorsController extends ChangeNotifier {
  SchoolDirectorsController(this._gateway);
  final SchoolDirectorGateway _gateway;
  List<DirectorSchool> schools = const [];
  DirectorSchool? school;
  DirectorDirectory? directory;
  DirectorFailure? error;
  bool loading = false;
  bool saving = false;
  bool saved = false;
  bool _disposed = false;
  int _revision = 0;

  bool get canMutate => !_disposed && !loading && !saving && directory != null;

  Future<void> initialize() async {
    if (loading || saving) return;
    final revision = ++_revision;
    loading = true;
    error = null;
    _emit();
    try {
      final result = await _gateway.schools();
      if (!_current(revision)) return;
      schools = List.unmodifiable(result);
    } on DirectorApiException catch (failure) {
      if (_current(revision)) error = failure.failure;
    } finally {
      if (_current(revision)) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> select(DirectorSchool selected) async {
    if (saving || !schools.contains(selected)) return;
    final revision = ++_revision;
    school = selected;
    directory = null;
    error = null;
    saved = false;
    loading = true;
    _emit();
    try {
      final result = await _gateway.directory(selected);
      if (_current(revision)) directory = result;
    } on DirectorApiException catch (failure) {
      if (_current(revision)) error = failure.failure;
    } finally {
      if (_current(revision)) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> reload() => school == null ? initialize() : select(school!);

  Future<bool> saveProfile(DirectorDraft draft, {int? directorId}) => _mutate(
    (selected) => _gateway.save(selected, draft, directorId: directorId),
  );

  Future<bool> assign(int directorId, DateTime startsOn) => _mutate(
    (selected) => _gateway.assign(
      selected,
      directorId,
      startsOn,
      replacesAssignmentId: directory?.current?.id,
    ),
  );

  Future<bool> end(DirectorAssignment assignment, DateTime endedOn) =>
      _mutate((selected) => _gateway.end(selected, assignment, endedOn));

  Future<bool> _mutate(Future<void> Function(DirectorSchool) action) async {
    if (!canMutate || school == null) return false;
    final selected = school!;
    saving = true;
    saved = false;
    error = null;
    _emit();
    var confirmed = false;
    try {
      await action(selected);
      confirmed = true;
      if (_disposed) return true;
      saved = true;
      directory = null;
      // Reload only the read. A failed refresh must never replay the mutation.
      directory = await _gateway.directory(selected);
    } on DirectorApiException catch (failure) {
      if (!_disposed) {
        error = failure.failure;
        if (confirmed ||
            const {
              DirectorFailure.uncertain,
              DirectorFailure.invalidResponse,
              DirectorFailure.server,
              DirectorFailure.conflict,
            }.contains(failure.failure)) {
          directory = null; // Require fresh state before another write.
        }
      }
    } finally {
      if (!_disposed) {
        saving = false;
        _emit();
      }
    }
    return confirmed;
  }

  bool _current(int revision) => !_disposed && revision == _revision;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
