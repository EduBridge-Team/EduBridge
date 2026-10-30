import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/institution_teacher_absence_repository.dart';
import '../../services/institution_timetable_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_substitute_screen.dart';
import 'institution_teacher_absence_controller.dart';
import 'institution_timetable_card.dart';

class InstitutionTeacherAbsenceScreen extends StatefulWidget {
  const InstitutionTeacherAbsenceScreen({super.key, required this.gateway, required this.timetableGateway, this.initialDate});
  final InstitutionTeacherAbsenceGateway gateway;
  final InstitutionTimetableGateway timetableGateway;
  final DateTime? initialDate;
  @override
  State<InstitutionTeacherAbsenceScreen> createState() => _InstitutionTeacherAbsenceScreenState();
}
class _InstitutionTeacherAbsenceScreenState extends State<InstitutionTeacherAbsenceScreen> with WidgetsBindingObserver {
  late InstitutionTeacherAbsenceController _state;
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _scroll = ScrollController();
  int? _teacher;
  late DateTime _date;
  void _initialize() {
    _date = widget.initialDate ?? DateTime.now();
    _state = InstitutionTeacherAbsenceController(widget.gateway)..reload();
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant InstitutionTeacherAbsenceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway || oldWidget.timetableGateway != widget.timetableGateway || oldWidget.initialDate != widget.initialDate) {
      _state.dispose(); _teacher = null; _reason.clear(); _initialize();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); _reason.dispose(); _scroll.dispose(); super.dispose(); }
  Future<void> _chooseDate() async {
    final controller = _state;
    final date = await showDatePicker(context: context, initialDate: _date,
      firstDate: DateTime(1900), lastDate: DateTime(2200, 12, 31));
    if (mounted && identical(controller, _state) && controller.canWrite && date != null) setState(() => _date = date);
  }
  Future<void> _save() async {
    final controller = _state, data = _state.snapshot, teacher = _teacher;
    if (!controller.canWrite || data == null || teacher == null || !(_form.currentState?.validate() ?? false)) return;
    final reason = _reason.text.trim().isEmpty ? null : _reason.text.trim(), date = _date;
    final confirmed = await showDialog<bool>(context: context, builder: (context) {
      final l = context.l10n;
      return AlertDialog(scrollable: true, title: Text(l.teacherAbsenceTitle), content: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(data.teachers[teacher]!), Text(MaterialLocalizations.of(context).formatMediumDate(date)),
          if (reason != null) Text(reason), Text(l.teacherAbsenceNotice),
        ]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(key: const ValueKey('absence-confirm'), onPressed: () => Navigator.pop(context, true), child: Text(l.enrollmentConfirm))]);
    });
    if (!mounted || !identical(controller, _state) || confirmed != true ||
        !controller.canWrite || !identical(data, controller.snapshot) ||
        teacher != _teacher || !data.teachers.containsKey(teacher) ||
        _date != date || _reason.text.trim() != (reason ?? '') ||
        _form.currentState?.validate() != true) return;
    await controller.report(teacher, date, reason);
    if (mounted && identical(controller, _state) && _scroll.hasClients) _scroll.jumpTo(0);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n, data = _state.snapshot, receipt = _state.receipt;
    if (data != null && !data.teachers.containsKey(_teacher)) _teacher = null;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(l.teacherAbsenceTitle), actions: [
        IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading || _state.busy ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: Form(key: _form, child: ListView(controller: _scroll, padding: const EdgeInsets.all(16), children: [
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(l, _state.error!))),
          if (receipt != null) ...[
            Semantics(liveRegion: true, child: Text(l.enrollmentSaved, key: const ValueKey('absence-saved'))),
            Text(receipt.teacherName), Text(MaterialLocalizations.of(context).formatMediumDate(receipt.date)),
            if (receipt.reason != null) Text(receipt.reason!), Text(l.teacherAbsenceAffected),
            if (receipt.affected.isEmpty) Text(l.teacherAbsenceEmpty),
            for (final entry in receipt.affected) InstitutionTimetableCard(
              timetable: receipt.timetable, entry: entry,
              onChoose: !_state.canWrite || !receipt.timetable.acceptsDate(entry, receipt.date) ? null : () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InstitutionSubstituteScreen(
                  gateway: widget.timetableGateway, timetable: receipt.timetable, entry: entry, initialDate: receipt.date)));
                if (mounted) await _state.reload();
              }),
            if (receipt.affected.any((e) => !receipt.timetable.acceptsDate(e, receipt.date))) Text(l.teacherAbsenceOutsideYear),
            Text(l.teacherAbsenceReceiptNotice),
          ] else if (data != null) ...[
            Text(data.timetable.academic.school.name), Text(l.teacherAbsenceNotice),
            AcademicChoiceField(key: const ValueKey('absence-teacher'), label: l.teacherAssignmentTeacher,
              options: data.teachers, value: _teacher, requiredMessage: l.academicRequired,
              onChanged: _state.canWrite ? (v) => setState(() => _teacher = v) : null),
            OutlinedButton(key: const ValueKey('absence-date'), onPressed: _state.canWrite ? _chooseDate : null,
              child: Text(MaterialLocalizations.of(context).formatMediumDate(_date))),
            TextFormField(key: const ValueKey('absence-reason'), controller: _reason, enabled: _state.canWrite,
              maxLines: null, decoration: InputDecoration(labelText: l.teacherAbsenceReason),
              validator: (v) => (v?.length ?? 0) <= 2000 ? null : l.institutionAttendanceNoteInvalid),
            FilledButton(key: const ValueKey('absence-submit'), onPressed: _state.canWrite && _teacher != null ? _save : null,
              child: Text(l.teacherAbsenceTitle)),
          ],
        ])),
      ))),
    ));
  });
}
