import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_attendance_draft.dart';
import '../../services/institution_attendance_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_attendance_write_controller.dart';

class InstitutionAttendanceCreateScreen extends StatefulWidget {
  const InstitutionAttendanceCreateScreen({super.key, required this.writer, this.initialDate});
  final InstitutionAttendanceWriter writer;
  final DateTime? initialDate;
  @override
  State<InstitutionAttendanceCreateScreen> createState() => _InstitutionAttendanceCreateScreenState();
}
class _InstitutionAttendanceCreateScreenState extends State<InstitutionAttendanceCreateScreen> with WidgetsBindingObserver {
  late AttendanceCreateController _state;
  final _form = GlobalKey<FormState>();
  final _period = TextEditingController(), _notes = TextEditingController();
  int? _section;
  int _subject = 0;
  late DateTime _date;
  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _state = AttendanceCreateController(widget.writer)..reload();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void didUpdateWidget(covariant InstitutionAttendanceCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.writer != oldWidget.writer || widget.initialDate != oldWidget.initialDate) {
      _state.dispose();
      _section = null;
      _subject = 0;
      _period.clear();
      _notes.clear();
      _date = widget.initialDate ?? DateTime.now();
      _state = AttendanceCreateController(widget.writer)..reload();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose(); _period.dispose(); _notes.dispose();
    super.dispose();
  }
  Future<void> _save() async {
    if (!_state.canWrite || !(_form.currentState?.validate() ?? false)) return;
    final controller = _state;
    final date = _date;
    await controller.create(AttendanceSessionDraft(sectionId: _section!, date: _date,
      subjectId: _subject == 0 ? null : _subject, period: int.tryParse(_period.text.trim()),
      note: _notes.text.isEmpty ? null : _notes.text));
    if (mounted && identical(controller, _state) && controller.saved && controller.createdId != null) {
      Navigator.pop(context, (controller.createdId!, date));
    }
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n;
    final data = _state.snapshot;
    final enabled = _state.canWrite;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(l.institutionAttendanceCreate),
        actions: [IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading || _state.busy ? null : _state.reload,
          icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(l, _state.error!))),
          if (data != null) ...[
            Text(data.academic.school.name),
            Text(l.institutionAttendanceInitializeNotice),
            AcademicChoiceField(key: const ValueKey('attendance-create-section'), label: l.enrollmentSection,
              options: {for (final section in data.academic.sections) section.id:
                '${data.academic.years.firstWhere((y) => y.id == section.yearId).name} — ${data.academic.grades.firstWhere((g) => g.id == section.gradeId).name} — ${section.name}'},
              value: _section, requiredMessage: l.academicRequired,
              onChanged: enabled ? (v) => setState(() => _section = v) : null),
            AcademicChoiceField(key: const ValueKey('attendance-create-subject'), label: l.curriculumSubjects,
              options: {0: l.institutionAttendanceNoSubject, for (final subject in data.academic.curriculum.subjects.where((s) => s.active)) subject.id: subject.name},
              value: _subject, requiredMessage: l.academicRequired,
              onChanged: enabled ? (v) => setState(() => _subject = v) : null),
            OutlinedButton(key: const ValueKey('attendance-create-date'), onPressed: !enabled ? null : () async {
              final controller = _state;
              final date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime(2100, 12, 31));
              if (mounted && date != null && identical(controller, _state) && controller.canWrite) setState(() => _date = date);
            }, child: Text(MaterialLocalizations.of(context).formatMediumDate(_date))),
            TextFormField(key: const ValueKey('attendance-create-period'), controller: _period, enabled: enabled,
              keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.institutionAttendancePeriodOptional),
              validator: (v) => v == null || v.trim().isEmpty || (int.tryParse(v.trim()) != null && int.parse(v.trim()) >= 1 && int.parse(v.trim()) <= 20)
                ? null : l.institutionAttendancePeriodInvalid),
            TextFormField(key: const ValueKey('attendance-create-note'), controller: _notes, enabled: enabled,
              decoration: InputDecoration(labelText: l.institutionAttendanceNote), maxLines: null,
              validator: (v) => (v?.length ?? 0) <= 2000 ? null : l.institutionAttendanceNoteInvalid),
            FilledButton(key: const ValueKey('attendance-create-save'), onPressed: enabled && data.academic.sections.isNotEmpty ? _save : null,
              child: Text(l.institutionAttendanceCreate)),
            if (data.academic.sections.isEmpty) Text(l.enrollmentNoSections),
          ],
        ])),
      ))),
    ));
  });
}
