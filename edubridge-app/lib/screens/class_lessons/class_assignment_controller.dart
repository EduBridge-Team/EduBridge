import 'package:flutter/foundation.dart';
import '../../model/class_lessons/class_lesson_assignment.dart';
import '../../services/class_assignment_repository.dart';
import '../../services/enrollment/enrollment_api_client.dart';

class ClassAssignmentController extends ChangeNotifier {
  ClassAssignmentController(this.gateway);
  final ClassAssignmentGateway gateway;
  ClassAssignmentOptions? options;
  EnrollmentFailure? error;
  int? lessonId, assignmentId;
  final Map<int, ClassAssignmentGoal> _goals = {};
  final Map<int, String> _adaptations = {};
  bool loading = false, busy = false, locked = false, _disposed = false;
  int generation = 0;
  bool get editable => !_disposed && !loading && !busy && !locked && assignmentId == null && options?.canAssign == true;
  bool get canSubmit => editable && lessonId != null && draft().fits(options!);
  ClassAssignmentGoal? goal(int childId) => _goals[childId];
  String adaptation(int childId) => _adaptations[childId] ?? '';
  void _emit() { if (!_disposed) notifyListeners(); }
  bool accepts(ClassAssignmentOptions expected, int epoch) => editable &&
    identical(options, expected) && generation == epoch;
  void chooseLesson(int id, ClassAssignmentOptions expected, int epoch) {
    if (!accepts(expected, epoch) || !expected.lessons.containsKey(id)) return;
    lessonId = id; _emit();
  }
  void chooseGoal(int childId, int id, ClassAssignmentOptions expected, int epoch) {
    if (!accepts(expected, epoch)) return;
    final student = expected.students.where((s) => s.id == childId);
    if (student.length != 1) return;
    if (id == 0) { _goals.remove(childId); }
    else {
      final goals = student.single.goals.where((g) => g.id == id);
      if (goals.length != 1) return;
      _goals[childId] = goals.single;
    }
    _emit();
  }
  void adapt(int childId, String value, ClassAssignmentOptions expected, int epoch) {
    if (!accepts(expected, epoch) || !expected.students.any((s) => s.id == childId)) return;
    _adaptations[childId] = value;
    _emit();
  }
  ClassAssignmentDraft draft() => ClassAssignmentDraft(lessonId!, [for (final s in options!.students)
    ClassAssignmentChoice(childId: s.id, goal: _goals[s.id], adaptation: _adaptations[s.id] ?? '')]);
  Future<void> reload() async {
    if (_disposed || loading || busy || assignmentId != null) return;
    generation++;
    loading = true; error = null; options = null; lessonId = null; _goals.clear(); _adaptations.clear(); _emit();
    try {
      final result = await gateway.load();
      if (!_disposed) options = result;
    } on EnrollmentApiException catch (e) { if (!_disposed) error = e.failure; }
    on Exception { if (!_disposed) error = EnrollmentFailure.network; }
    finally { loading = false; _emit(); }
  }
  Future<void> submit(ClassAssignmentOptions expected, int epoch, ClassAssignmentDraft confirmed) async {
    if (!accepts(expected, epoch) || !canSubmit || !confirmed.fits(expected)) return;
    busy = true; error = null; _emit();
    try {
      assignmentId = await gateway.assign(expected, confirmed, newClassAssignmentKey());
      options = null;
    } on EnrollmentApiException catch (e) {
      error = e.failure;
      locked = [EnrollmentFailure.uncertain, EnrollmentFailure.conflict].contains(e.failure);
      options = null;
    } on Exception { error = EnrollmentFailure.uncertain; locked = true; options = null; }
    finally { busy = false; _emit(); }
  }
  @override
  void dispose() { _disposed = true; generation++; super.dispose(); }
}
