import '../enrollment/enrollment_models.dart';
import 'institution_academic_records.dart';

// The institution API uses 1=Sunday through 7=Saturday.
int institutionWeekday(DateTime date) => date.weekday % 7 + 1;
DateTime timetableDate(DateTime date) => DateTime(date.year, date.month, date.day);
String? _time(dynamic value) {
  if (value == null) return null;
  if (value is! String || !RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(value)) {
    throw const FormatException('Invalid timetable time');
  }
  final parts = value.split(':').map(int.parse).toList();
  if (parts[0] > 23 || parts[1] > 59 || (parts.length == 3 && parts[2] > 59)) {
    throw const FormatException('Invalid timetable time');
  }
  return parts.length == 2 ? '$value:00' : value;
}
class InstitutionTimetableEntry {
  const InstitutionTimetableEntry(this.id, this.schoolId, this.yearId, this.sectionId, this.subjectId,
    this.teacherId, this.teacherName, this.weekday, this.period, this.startsAt, this.endsAt, this.room);
  final int id, schoolId, yearId, sectionId, subjectId, weekday, period;
  final int? teacherId;
  final String? teacherName, startsAt, endsAt, room;
  Object get identity => (id, schoolId, yearId, sectionId, subjectId, teacherId, weekday, period, startsAt, endsAt, room);
  factory InstitutionTimetableEntry.fromJson(InstitutionAcademicRecords academic, Map<String, dynamic> row) {
    final sectionId = enrollmentId(row['section_id']);
    final sections = academic.sections.where((s) => s.id == sectionId);
    final yearId = enrollmentId(row['academic_year_id']);
    final subjectId = enrollmentId(row['subject_id']);
    final day = row['weekday'], period = row['period_number'];
    final teacher = row['teacher_id'] == null ? null : enrollmentId(row['teacher_id']);
    final name = row['teacher_name'] == null ? null : enrollmentText(row['teacher_name']);
    final start = _time(row['starts_at']), end = _time(row['ends_at']);
    final room = row['room'];
    if (enrollmentId(row['school_id']) != academic.school.id || sections.length != 1 ||
        sections.single.yearId != yearId || !academic.years.any((y) => y.id == yearId) ||
        !academic.curriculum.subjects.any((s) => s.id == subjectId) ||
        day is! int || day < 1 || day > 7 || period is! int || period < 1 || period > 20 ||
        (teacher != null && name == null) || (teacher == null && name != null) ||
        (room != null && (room is! String || room.length > 80)) ||
        (start != null && end != null && end.compareTo(start) <= 0)) {
      throw const FormatException('Invalid timetable scope or slot');
    }
    return InstitutionTimetableEntry(enrollmentId(row['id']), academic.school.id, yearId, sectionId, subjectId,
      teacher, name, day, period, start, end, room as String?);
  }
}
class InstitutionTimetable {
  InstitutionTimetable(this.academic, List<InstitutionTimetableEntry> entries) : entries = List.unmodifiable(entries);
  final InstitutionAcademicRecords academic;
  final List<InstitutionTimetableEntry> entries;
  factory InstitutionTimetable.fromJson(InstitutionAcademicRecords academic, Map<String, dynamic> data) {
    final entries = enrollmentList(data['timetable']).map((r) => InstitutionTimetableEntry.fromJson(academic, enrollmentMap(r))).toList();
    if (entries.map((e) => e.id).toSet().length != entries.length ||
        entries.map((e) => (e.sectionId, e.weekday, e.period)).toSet().length != entries.length) {
      throw const FormatException('Duplicate timetable entry');
    }
    entries.sort((a, b) {
      final day = a.weekday.compareTo(b.weekday);
      return day == 0 ? a.period.compareTo(b.period) : day;
    });
    return InstitutionTimetable(academic, entries);
  }
  String sectionLabel(int id) {
    final section = academic.sections.firstWhere((s) => s.id == id);
    final grade = academic.grades.firstWhere((g) => g.id == section.gradeId);
    final year = academic.years.firstWhere((y) => y.id == section.yearId);
    return '${year.name} — ${grade.name} — ${section.name}';
  }
  bool acceptsDate(InstitutionTimetableEntry entry, DateTime date) {
    final year = academic.years.firstWhere((y) => y.id == entry.yearId);
    final day = timetableDate(date);
    return institutionWeekday(day) == entry.weekday && !day.isBefore(year.start) && !day.isAfter(year.end);
  }
  DateTime? nextDate(InstitutionTimetableEntry entry, DateTime from) {
    final year = academic.years.firstWhere((y) => y.id == entry.yearId);
    var day = timetableDate(from);
    if (day.isBefore(year.start) || day.isAfter(year.end)) day = year.start;
    day = day.add(Duration(days: (entry.weekday - institutionWeekday(day) + 7) % 7));
    return day.isAfter(year.end) ? null : day;
  }
}
class InstitutionSubstituteChoices {
  InstitutionSubstituteChoices(this.timetable, this.entry, this.date, Map<int, String> teachers)
    : teachers = Map.unmodifiable(teachers);
  final InstitutionTimetable timetable;
  final InstitutionTimetableEntry entry;
  final DateTime date;
  final Map<int, String> teachers;
}
class InstitutionSubstitutionReceipt {
  const InstitutionSubstitutionReceipt(this.id, this.teacherName, this.date);
  final int id;
  final String teacherName;
  final DateTime date;
}
