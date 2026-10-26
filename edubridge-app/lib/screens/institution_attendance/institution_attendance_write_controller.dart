import '../../model/institutions/institution_attendance.dart';
import '../../model/institutions/institution_attendance_draft.dart';
import '../../services/institution_attendance_repository.dart';
import '../enrollment/enrollment_state.dart';

class AttendanceCreateController extends EnrollmentState<InstitutionAttendanceView> {
  AttendanceCreateController(this.writer) : super(() => writer.load());
  final InstitutionAttendanceWriter writer;
  int? createdId;
  Future<void> create(AttendanceSessionDraft draft) => mutate(() async {
    createdId = await writer.createAttendance(draft);
  });
}
class AttendanceMarkController extends EnrollmentState<AttendanceEditorData> {
  AttendanceMarkController(this.writer, this.sessionId, this.date)
    : super(() => writer.loadEditor(sessionId: sessionId, date: date));
  final InstitutionAttendanceWriter writer;
  final int sessionId;
  final DateTime date;
  Future<void> save(AttendanceEditorData expected, Map<int, AttendanceMark> marks, bool close) =>
    mutate(() => writer.saveAttendance(expected, Map.unmodifiable(marks), closeSession: close));
}
