import 'institution_timetable.dart';

bool timetableInputTime(String? value) => value == null ||
  (RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value));

class TimetableEntryDraft {
  const TimetableEntryDraft({required this.yearId, required this.sectionId, required this.subjectId,
    required this.weekday, required this.period, this.teacherId, this.startsAt, this.endsAt, this.room});
  final int yearId, sectionId, subjectId, weekday, period;
  final int? teacherId;
  final String? startsAt, endsAt, room;
  bool get valid => yearId > 0 && sectionId > 0 && subjectId > 0 && (teacherId == null || teacherId! > 0) &&
    weekday >= 1 && weekday <= 7 && period >= 1 && period <= 20 && (room?.length ?? 0) <= 80 &&
    timetableInputTime(startsAt) && timetableInputTime(endsAt) &&
    (endsAt == null || (startsAt != null && endsAt!.compareTo(startsAt!) > 0));
  Map<String, dynamic> toJson() => {'academic_year_id': yearId, 'section_id': sectionId, 'subject_id': subjectId,
    'teacher_id': teacherId, 'weekday': weekday, 'period_number': period,
    'starts_at': startsAt, 'ends_at': endsAt, 'room': room};
  bool conflicts(InstitutionTimetable timetable) => timetable.entries.any((e) =>
    e.yearId == yearId && e.weekday == weekday && e.period == period &&
    (e.sectionId == sectionId || (teacherId != null && e.teacherId == teacherId) ||
      (room != null && room!.isNotEmpty && e.room == room)));
  bool matches(InstitutionTimetableEntry entry) => entry.yearId == yearId && entry.sectionId == sectionId &&
    entry.subjectId == subjectId && entry.teacherId == teacherId && entry.weekday == weekday && entry.period == period &&
    entry.startsAt == (startsAt == null ? null : '$startsAt:00') &&
    entry.endsAt == (endsAt == null ? null : '$endsAt:00') && entry.room == room;
}
class TimetableCreationData {
  TimetableCreationData(this.timetable, Map<int, String> teachers) : teachers = Map.unmodifiable(teachers);
  final InstitutionTimetable timetable;
  final Map<int, String> teachers;
  bool accepts(TimetableEntryDraft draft) => draft.valid &&
    timetable.academic.years.any((y) => y.id == draft.yearId) &&
    timetable.academic.sections.any((s) => s.id == draft.sectionId && s.yearId == draft.yearId) &&
    timetable.academic.curriculum.subjects.any((s) => s.id == draft.subjectId && s.active) &&
    (draft.teacherId == null || teachers.containsKey(draft.teacherId));
}
