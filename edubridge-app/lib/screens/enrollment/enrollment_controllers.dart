import '../../model/enrollment/enrollment_models.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/enrollment/enrollment_repository.dart';
import 'enrollment_state.dart';

class SchoolEnrollmentController
    extends EnrollmentState<SchoolEnrollmentInbox> {
  SchoolEnrollmentController(this._gateway) : super(_gateway.load);
  final SchoolEnrollmentGateway _gateway;
  Future<void> decide(
    EnrollmentRequest request,
    EnrollmentDecision decision,
  ) async {
    if (!canWrite ||
        !snapshot!.requests.contains(request) ||
        request.status != EnrollmentStatus.pending)
      return;
    if (decision.approve
        ? !snapshot!.sections.any((s) => s.id == decision.sectionId)
        : decision.reason.trim().isEmpty)
      return;
    await mutate(() => _gateway.decide(request, decision));
  }
}

class ParentEnrollmentController
    extends EnrollmentState<ParentEnrollmentHistory> {
  ParentEnrollmentController(this._gateway) : super(_gateway.load);
  final ParentEnrollmentGateway _gateway;
  List<EnrollmentSchool> _schools = const [];
  List<EnrollmentSchool> get schools => _schools;
  bool _searching = false, _searched = false;
  bool get searching => _searching;
  bool get searched => _searched;
  EnrollmentFailure? _searchError;
  EnrollmentFailure? get searchError => _searchError;
  int _generation = 0;

  void clearSearch() {
    _generation++;
    _schools = const [];
    _searching = false;
    _searched = false;
    _searchError = null;
    emit();
  }

  Future<void> search(String query) async {
    if (!isAlive || busy) return;
    final value = query.trim();
    final generation = ++_generation;
    _schools = const [];
    _searchError = null;
    _searched = false;
    if (value.length < 2 || value.length > 100) {
      _searching = false;
      _searchError = EnrollmentFailure.validation;
      emit();
      return;
    }
    _searching = true;
    emit();
    try {
      final result = await _gateway.search(value);
      if (isAlive && generation == _generation) {
        _schools = List.unmodifiable(result);
        _searched = true;
      }
    } on EnrollmentApiException catch (e) {
      if (isAlive && generation == _generation) _searchError = e.failure;
    } finally {
      if (isAlive && generation == _generation) {
        _searching = false;
        emit();
      }
    }
  }

  Future<void> submit(EnrollmentSchool school) async {
    if (!canWrite || !snapshot!.canRequest || !_schools.contains(school))
      return;
    await mutate(() => _gateway.submit(school));
  }

  Future<void> cancel(EnrollmentRequest request) async {
    if (!canWrite ||
        !snapshot!.requests.contains(request) ||
        request.status != EnrollmentStatus.pending)
      return;
    await mutate(() => _gateway.cancel(request));
  }
}
