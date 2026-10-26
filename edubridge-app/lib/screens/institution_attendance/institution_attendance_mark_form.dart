import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_attendance.dart';
import '../../model/institutions/institution_attendance_draft.dart';
import '../academics/academic_choice_field.dart';
import 'institution_attendance_content.dart';

class AttendanceMarkForm extends StatefulWidget {
  const AttendanceMarkForm({super.key, required this.data, required this.enabled, required this.onSave});
  final AttendanceEditorData data;
  final bool enabled;
  final Future<void> Function(AttendanceEditorData, Map<int, AttendanceMark>, bool) onSave;
  @override
  State<AttendanceMarkForm> createState() => _AttendanceMarkFormState();
}
class _AttendanceMarkFormState extends State<AttendanceMarkForm> {
  final _form = GlobalKey<FormState>();
  final _statuses = <int, InstitutionAttendanceStatus?>{};
  final _notes = <int, TextEditingController>{};
  bool _close = false;
  @override
  void initState() {
    super.initState();
    for (final student in widget.data.students) {
      _statuses[student.id] = student.record?.status;
      _notes[student.id] = TextEditingController(text: student.record?.note ?? '');
    }
  }
  @override
  void dispose() {
    for (final controller in _notes.values) { controller.dispose(); }
    super.dispose();
  }
  Future<void> _save() async {
    if (!widget.enabled || !(_form.currentState?.validate() ?? false)) return;
    if (_close) {
      final confirmed = await showDialog<bool>(context: context, builder: (context) {
        final l = context.l10n;
        return AlertDialog(scrollable: true, title: Text(l.institutionAttendanceClose), content: Text(l.institutionAttendanceCloseNotice),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(key: const ValueKey('attendance-confirm-close'), onPressed: () => Navigator.pop(context, true), child: Text(l.enrollmentConfirm))]);
      });
      if (confirmed != true || !mounted || !widget.enabled) return;
    }
    await widget.onSave(widget.data, {for (final student in widget.data.students)
      student.id: AttendanceMark(_statuses[student.id]!, _notes[student.id]!.text)}, _close);
  }
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final closed = widget.data.view.session!.closed;
    final enabled = widget.enabled && !closed;
    return Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.data.view.academic.school.name),
      Text(widget.data.view.sectionLabel(widget.data.view.session!)),
      Text(MaterialLocalizations.of(context).formatMediumDate(widget.data.view.session!.date)),
      if (closed) Text(l.institutionAttendanceClosed),
      if (widget.data.students.isEmpty) Text(l.institutionAttendanceNoRecords),
      for (final student in widget.data.students) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(student.name, style: Theme.of(context).textTheme.titleMedium),
          AcademicChoiceField(key: ValueKey('attendance-mark-${student.id}'), label: l.status,
            options: {for (final status in InstitutionAttendanceStatus.values) status.index: attendanceStatusLabel(l, status)},
            value: _statuses[student.id]?.index, requiredMessage: l.academicRequired,
            onChanged: enabled ? (v) => setState(() => _statuses[student.id] = InstitutionAttendanceStatus.values[v]) : null),
          TextFormField(key: ValueKey('attendance-note-${student.id}'), controller: _notes[student.id], enabled: enabled,
            decoration: InputDecoration(labelText: l.institutionAttendanceNote), maxLines: null,
            validator: (v) => (v?.length ?? 0) <= 1000 ? null : l.institutionAttendanceNoteInvalid),
        ],
      ))),
      CheckboxListTile(key: const ValueKey('attendance-close'), value: _close,
        onChanged: enabled ? (v) => setState(() => _close = v ?? false) : null,
        title: Text(l.institutionAttendanceClose), subtitle: Text(l.institutionAttendanceCloseNotice)),
      FilledButton(key: const ValueKey('attendance-mark-save'), onPressed: enabled && widget.data.students.isNotEmpty ? _save : null,
        child: Text(l.save)),
    ]));
  }
}
