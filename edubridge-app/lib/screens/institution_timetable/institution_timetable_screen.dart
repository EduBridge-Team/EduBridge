import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_timetable.dart';
import '../../model/institutions/institution_timetable_draft.dart';
import '../../services/institution_timetable_repository.dart';
import '../../theme.dart';
import '../../services/institution_teacher_absence_repository.dart';
import 'institution_teacher_absence_screen.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_timetable_controller.dart';
import 'institution_substitute_screen.dart';
import 'institution_timetable_card.dart';
import 'institution_timetable_create_screen.dart';

class InstitutionTimetableScreen extends StatefulWidget {
  const InstitutionTimetableScreen({super.key, required this.gateway});
  final InstitutionTimetableGateway gateway;
  @override
  State<InstitutionTimetableScreen> createState() => _InstitutionTimetableScreenState();
}
class _InstitutionTimetableScreenState extends State<InstitutionTimetableScreen> with WidgetsBindingObserver {
  late InstitutionTimetableController _state;
  int _year = 0, _section = 0, _day = 0, _teacher = 0, _subject = 0;
  void _initialize() { _state = InstitutionTimetableController(widget.gateway)..reload(); }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant InstitutionTimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) {
      _state.dispose(); _year = 0; _section = 0; _day = 0; _teacher = 0; _subject = 0; _initialize();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<void> _remove(InstitutionTimetableEntry entry) async {
    final controller = _state, expected = _state.snapshot;
    if (!controller.canWrite || expected == null) return;
    final l = context.l10n;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(l.timetableDelete), content: Text(l.timetableDeleteConfirm),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.timetableDeleteCancel)),
        FilledButton(key: const ValueKey('timetable-delete-confirm'),
          onPressed: () => Navigator.pop(context, true), child: Text(l.timetableDelete))],
      scrollable: true,
    ));
    if (!mounted || !identical(controller, _state) || !identical(expected, controller.snapshot) || confirmed != true) return;
    await controller.remove(entry);
    if (mounted && identical(controller, _state) && controller.saved) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.timetableDeleted)));
    }
  }
  Future<void> _absence() async {
    final controller = _state, gateway = widget.gateway;
    if (!controller.canWrite || gateway is! InstitutionTeacherAbsenceGateway) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      InstitutionTeacherAbsenceScreen(gateway: gateway as InstitutionTeacherAbsenceGateway, timetableGateway: gateway)));
    if (mounted && identical(controller, _state)) await controller.reload();
  }
  Future<void> _create() async {
    final controller = _state, gateway = widget.gateway;
    if (!controller.canWrite || gateway is! InstitutionTimetableCreator) return;
    final draft = await Navigator.of(context).push<TimetableEntryDraft>(MaterialPageRoute(builder: (_) =>
      InstitutionTimetableCreateScreen(writer: gateway)));
    if (!mounted || !identical(controller, _state)) return;
    if (draft != null) setState(() { _year = draft.yearId; _section = draft.sectionId; _day = draft.weekday; });
    await controller.reload();
    if (mounted && draft != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.enrollmentSaved)));
  }
  Future<void> _open(InstitutionTimetable data, InstitutionTimetableEntry entry) async {
    final controller = _state;
    if (!controller.canWrite) return;
    final gateway = widget.gateway;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      InstitutionSubstituteScreen(gateway: gateway, timetable: data, entry: entry)));
    if (mounted && identical(controller, _state)) await controller.reload();
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n, data = _state.snapshot;
    if (data != null) {
      if (!data.academic.years.any((y) => y.id == _year)) _year = 0;
      if (!data.academic.sections.any((s) => s.id == _section && (_year == 0 || s.yearId == _year))) _section = 0;
      if (!data.entries.any((e) => e.teacherId == _teacher)) _teacher = 0;
      if (!data.academic.curriculum.subjects.any((s) => s.id == _subject)) _subject = 0;
    }
    final entries = data?.entries.where((e) => (_year == 0 || e.yearId == _year) &&
      (_section == 0 || e.sectionId == _section) && (_day == 0 || e.weekday == _day) &&
      (_teacher == 0 || e.teacherId == _teacher) && (_subject == 0 || e.subjectId == _subject)).toList();
    return PopScope(canPop: !_state.busy, child: Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(l.timetableTitle),
      actions: [IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading || _state.busy ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _state.reload, child: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(padding: const EdgeInsets.all(16), physics: const AlwaysScrollableScrollPhysics(), children: [
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(l, _state.error!))),
          if (data != null) ...[
            Text(data.academic.school.name, style: Theme.of(context).textTheme.titleLarge),
            if (widget.gateway is InstitutionTeacherAbsenceGateway) FilledButton(key: const ValueKey('timetable-open-absence'),
              onPressed: _state.canWrite ? _absence : null, child: Text(l.teacherAbsenceTitle)),
            if (widget.gateway is InstitutionTimetableCreator) FilledButton(key: const ValueKey('timetable-open-create'),
              onPressed: _state.canWrite ? _create : null, child: Text(l.timetableCreate)),
            AcademicChoiceField(key: const ValueKey('timetable-year'), label: l.academicYears,
              options: {0: l.all, for (final y in data.academic.years) y.id: y.name}, value: _year,
              requiredMessage: l.academicRequired, onChanged: !_state.canWrite ? null : (v) => setState(() { _year = v; _section = 0; })),
            AcademicChoiceField(key: const ValueKey('timetable-section'), label: l.academicSections,
              options: {0: l.all, for (final s in data.academic.sections.where((s) => _year == 0 || s.yearId == _year)) s.id: data.sectionLabel(s.id)},
              value: _section, requiredMessage: l.academicRequired, onChanged: !_state.canWrite ? null : (v) => setState(() => _section = v)),
            AcademicChoiceField(key: const ValueKey('timetable-day'), label: l.timetableDay, options: timetableDays(l),
              value: _day, requiredMessage: l.academicRequired, onChanged: !_state.canWrite ? null : (v) => setState(() => _day = v)),
            AcademicChoiceField(key: const ValueKey('timetable-teacher'), label: l.teacherAssignmentTeacher,
              options: {0: l.all, for (final e in data.entries.where((e) => e.teacherId != null && e.teacherName != null)) e.teacherId!: e.teacherName!},
              value: _teacher, requiredMessage: l.academicRequired, onChanged: (v) => setState(() => _teacher = v)),
            AcademicChoiceField(key: const ValueKey('timetable-subject'), label: l.academicSubjects,
              options: {0: l.all, for (final s in data.academic.curriculum.subjects) s.id: s.name},
              value: _subject, requiredMessage: l.academicRequired, onChanged: (v) => setState(() => _subject = v)),
            if (entries!.isEmpty) Text(l.timetableEmpty),
            for (final entry in entries) InstitutionTimetableCard(key: ValueKey('timetable-entry-${entry.id}'),
              timetable: data, entry: entry,
              onRemove: widget.gateway is InstitutionTimetableRemover && _state.canWrite ? () => _remove(entry) : null, onChoose: !_state.canWrite ? null : () => _open(data, entry)),
          ],
        ]),
      )))),
    ));
  });
}
