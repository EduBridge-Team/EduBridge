import '../../model/institutions/institution_teacher_absence.dart';
import '../../model/institutions/institution_timetable_draft.dart';
import '../../services/institution_teacher_absence_repository.dart';
import '../enrollment/enrollment_state.dart';

class InstitutionTeacherAbsenceController extends EnrollmentState<TimetableCreationData> {
  InstitutionTeacherAbsenceController(this.gateway) : super(gateway.loadAbsenceData);
  final InstitutionTeacherAbsenceGateway gateway;
  InstitutionTeacherAbsenceReceipt? receipt;
  Future<void> report(int teacherId, DateTime date, String? reason) => mutate(() async {
    receipt = await gateway.reportAbsence(teacherId, date, reason);
  });
}
