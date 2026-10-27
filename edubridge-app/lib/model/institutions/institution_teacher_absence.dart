import 'institution_timetable.dart';

class InstitutionTeacherAbsenceReceipt {
  InstitutionTeacherAbsenceReceipt(this.id, this.teacherId, this.teacherName, this.date,
    this.reason, this.timetable, List<InstitutionTimetableEntry> affected)
    : affected = List.unmodifiable(affected);
  final int id, teacherId;
  final String teacherName;
  final DateTime date;
  final String? reason;
  final InstitutionTimetable timetable;
  final List<InstitutionTimetableEntry> affected;
}
