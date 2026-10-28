import 'package:flutter/foundation.dart';
import '../../model/class_lessons/class_lesson_assignment.dart';
import '../../model/class_lessons/class_lesson_result.dart';
import '../../services/class_result_repository.dart';
import '../../services/enrollment/enrollment_api_client.dart';

class ClassResultController extends ChangeNotifier {
  ClassResultController(this.gateway);
  final ClassResultGateway gateway;
  ClassResultOptions? options;
  EnrollmentFailure? error;
  String? state;
  String score = '', maximum = '', measurement = '', observation = '';
  DateTime? observedOn;
  int? resultId;
  int generation = 0;
  bool loading = false, busy = false, locked = false, _disposed = false;
  bool get editable => !_disposed && !loading && !busy && !locked && resultId == null && options?.canRecord == true;
  ClassResultDraft? get draft {
    if (options == null || state == null || observedOn == null) return null;
    num? parse(String text) => text.trim().isEmpty ? null : num.tryParse(text.trim());
    if ([score, maximum, measurement].any((s) => s.trim().isNotEmpty && parse(s) == null)) return null;
    final result = ClassResultDraft(state: state!, observedOn: observedOn!, observation: observation,
      score: parse(score), maximum: parse(maximum), goalValue: parse(measurement));
    return result.fits(options!) ? result : null;
  }
  bool get canSubmit => editable && draft != null;
  bool accepts(ClassResultOptions expected, int epoch) => editable && identical(options, expected) && generation == epoch;
  void change(ClassResultOptions expected, int epoch, void Function() action) {
    if (!accepts(expected, epoch)) return;
    action(); notifyListeners();
  }
  void _emit() { if (!_disposed) notifyListeners(); }
  Future<void> reload() async {
    if (_disposed || loading || busy || resultId != null) return;
    generation++; loading = true; options = null; error = null;
    state = null; observedOn = null; score = ''; maximum = ''; measurement = ''; observation = ''; _emit();
    try {
      final result = await gateway.load();
      if (!_disposed) options = result;
    } on EnrollmentApiException catch (e) { if (!_disposed) error = e.failure; }
    on Exception { if (!_disposed) error = EnrollmentFailure.network; }
    finally { loading = false; _emit(); }
  }
  Future<void> submit(ClassResultOptions expected, int epoch, ClassResultDraft confirmed) async {
    if (!accepts(expected, epoch) || !canSubmit || !confirmed.fits(expected)) return;
    busy = true; error = null; _emit();
    try { resultId = await gateway.record(expected, confirmed, newClassAssignmentKey()); options = null; }
    on EnrollmentApiException catch (e) {
      error = e.failure; options = null;
      locked = [EnrollmentFailure.uncertain, EnrollmentFailure.conflict].contains(e.failure);
    } on Exception { error = EnrollmentFailure.uncertain; locked = true; options = null; }
    finally { busy = false; _emit(); }
  }
  @override
  void dispose() { _disposed = true; generation++; super.dispose(); }
}
