import '../../model/institutions/institution_timetable.dart';
import '../../services/institution_timetable_repository.dart';
import '../enrollment/enrollment_state.dart';

class InstitutionTimetableController extends EnrollmentState<InstitutionTimetable> {
  InstitutionTimetableController(this.gateway) : super(gateway.load);
  final InstitutionTimetableGateway gateway;
  Future<void> remove(InstitutionTimetableEntry entry) => mutate(() async {
    final writer = gateway;
    if (writer is InstitutionTimetableRemover) await writer.removeEntry(entry);
  });
}
