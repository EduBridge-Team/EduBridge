import '../../model/institutions/institution_timetable.dart';
import '../../services/institution_timetable_repository.dart';
import '../enrollment/enrollment_state.dart';

class InstitutionSubstituteController extends EnrollmentState<InstitutionSubstituteChoices> {
  InstitutionSubstituteController(this.gateway, this.entryId, this.date)
    : super(() => gateway.available(entryId, date));
  final InstitutionTimetableGateway gateway;
  final int entryId;
  final DateTime date;
  InstitutionSubstitutionReceipt? receipt;
  Future<void> assign(int teacherId, String? notes) {
    final expected = snapshot;
    if (expected == null) return Future.value();
    return mutate(() async { receipt = await gateway.assign(expected, teacherId, notes); });
  }
}
