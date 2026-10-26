import '../schools/academic_catalog.dart';
import 'institution_attendance.dart';

class AttendanceSessionDraft {
  const AttendanceSessionDraft({required this.sectionId, required this.date,
    this.subjectId, this.period, this.note});
  final int sectionId;
  final int? subjectId, period;
  final DateTime date;
  final String? note;
  bool get valid => sectionId > 0 && (subjectId == null || subjectId! > 0) &&
    (period == null || (period! >= 1 && period! <= 20)) && (note?.length ?? 0) <= 2000;
  Map<String, dynamic> toJson() => {'section_id': sectionId, 'subject_id': subjectId,
    'attendance_date': academicDateText(date), 'period_number': period, 'notes': note};
}
class AttendanceMark {
  const AttendanceMark(this.status, this.note);
  final InstitutionAttendanceStatus status;
  final String? note;
  bool get valid => (note?.length ?? 0) <= 1000;
  Map<String, dynamic> toJson(int childId) => {'child_id': childId, 'status': status.name,
    'note': note == '' ? null : note};
}
class AttendanceStudent {
  const AttendanceStudent(this.id, this.name, this.record);
  final int id;
  final String name;
  final InstitutionAttendanceRecord? record;
}
class AttendanceEditorData {
  AttendanceEditorData(this.view, List<AttendanceStudent> students) : students = List.unmodifiable(students);
  final InstitutionAttendanceView view;
  final List<AttendanceStudent> students;
}
