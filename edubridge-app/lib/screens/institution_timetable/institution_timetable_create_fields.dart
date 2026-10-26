import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_timetable_draft.dart';
import '../academics/academic_choice_field.dart';
import 'institution_timetable_card.dart';

class InstitutionTimetableCreateFields extends StatefulWidget {
  const InstitutionTimetableCreateFields({super.key, required this.data, required this.enabled, required this.onSubmit});
  final TimetableCreationData data;
  final bool enabled;
  final Future<void> Function(TimetableEntryDraft) onSubmit;
  @override
  State<InstitutionTimetableCreateFields> createState() => _InstitutionTimetableCreateFieldsState();
}
class _InstitutionTimetableCreateFieldsState extends State<InstitutionTimetableCreateFields> {
  final _form = GlobalKey<FormState>();
  final _period = TextEditingController(), _start = TextEditingController(), _end = TextEditingController(), _room = TextEditingController();
  int? _year, _section, _subject, _day, _teacher = 0;
  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();
  @override
  void dispose() {
    _period.dispose(); _start.dispose(); _end.dispose(); _room.dispose(); super.dispose();
  }
  Future<void> _submit() async {
    if (!widget.enabled || !(_form.currentState?.validate() ?? false)) return;
    await widget.onSubmit(TimetableEntryDraft(yearId: _year!, sectionId: _section!, subjectId: _subject!,
      teacherId: _teacher == 0 ? null : _teacher, weekday: _day!, period: int.parse(_period.text.trim()),
      startsAt: _optional(_start.text), endsAt: _optional(_end.text), room: _optional(_room.text)));
  }
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, data = widget.data;
    final academic = data.timetable.academic;
    final sections = academic.sections.where((s) => s.yearId == _year).toList();
    final subjects = academic.curriculum.subjects.where((s) => s.active).toList();
    if (_year != null && !academic.years.any((y) => y.id == _year)) { _year = null; _section = null; }
    if (_section != null && !sections.any((s) => s.id == _section)) _section = null;
    if (_subject != null && !subjects.any((s) => s.id == _subject)) _subject = null;
    if (_teacher != 0 && !data.teachers.containsKey(_teacher)) _teacher = null;
    final ready = academic.years.isNotEmpty && academic.sections.isNotEmpty && subjects.isNotEmpty;
    return Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(academic.school.name, style: Theme.of(context).textTheme.titleLarge),
      AcademicChoiceField(key: const ValueKey('timetable-create-year'), label: l.academicYears,
        options: {for (final year in academic.years) year.id: year.name}, value: _year, requiredMessage: l.academicRequired,
        onChanged: widget.enabled ? (v) => setState(() { _year = v; _section = null; }) : null),
      AcademicChoiceField(key: const ValueKey('timetable-create-section'), label: l.academicSections,
        options: {for (final section in sections) section.id: data.timetable.sectionLabel(section.id)},
        value: _section, requiredMessage: l.academicRequired,
        onChanged: widget.enabled ? (v) => setState(() => _section = v) : null),
      AcademicChoiceField(key: const ValueKey('timetable-create-subject'), label: l.curriculumSubjects,
        options: {for (final subject in subjects) subject.id: subject.name}, value: _subject, requiredMessage: l.academicRequired,
        onChanged: widget.enabled ? (v) => setState(() => _subject = v) : null),
      AcademicChoiceField(key: const ValueKey('timetable-create-teacher'), label: l.teacherAssignmentTeacher,
        options: {0: l.timetableNoTeacher, ...data.teachers}, value: _teacher, requiredMessage: l.academicRequired,
        onChanged: widget.enabled ? (v) => setState(() => _teacher = v) : null),
      AcademicChoiceField(key: const ValueKey('timetable-create-day'), label: l.timetableDay,
        options: Map.of(timetableDays(l))..remove(0), value: _day, requiredMessage: l.academicRequired,
        onChanged: widget.enabled ? (v) => setState(() => _day = v) : null),
      TextFormField(key: const ValueKey('timetable-create-period'), controller: _period, enabled: widget.enabled,
        keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.institutionAttendancePeriod),
        validator: (v) {
          final period = int.tryParse(v?.trim() ?? '');
          return period != null && period >= 1 && period <= 20 ? null : l.timetableCreatePeriodInvalid;
        }),
      Text(l.timetableCreateTimeHint),
      TextFormField(key: const ValueKey('timetable-create-start'), controller: _start, enabled: widget.enabled,
        textDirection: TextDirection.ltr, keyboardType: TextInputType.datetime,
        decoration: InputDecoration(labelText: l.timetableStarts, hintText: '08:00'),
        validator: (v) => timetableInputTime(_optional(v ?? '')) ? null : l.timetableCreateTimeInvalid),
      TextFormField(key: const ValueKey('timetable-create-end'), controller: _end, enabled: widget.enabled,
        textDirection: TextDirection.ltr, keyboardType: TextInputType.datetime,
        decoration: InputDecoration(labelText: l.timetableEnds, hintText: '08:45'),
        validator: (v) {
          final end = _optional(v ?? ''), start = _optional(_start.text);
          if (!timetableInputTime(end)) return l.timetableCreateTimeInvalid;
          if (end != null && (start == null || !timetableInputTime(start) || end.compareTo(start) <= 0)) return l.timetableCreateTimeOrder;
          return null;
        }),
      TextFormField(key: const ValueKey('timetable-create-room'), controller: _room, enabled: widget.enabled,
        maxLines: null, decoration: InputDecoration(labelText: l.timetableRoom),
        validator: (v) => (_optional(v ?? '')?.length ?? 0) <= 80 ? null : l.timetableCreateRoomInvalid),
      if (!ready) Text(l.timetableCreatePrerequisite),
      FilledButton(key: const ValueKey('timetable-create-submit'), onPressed: widget.enabled && ready ? _submit : null,
        child: Text(l.timetableCreate)),
    ]));
  }
}
