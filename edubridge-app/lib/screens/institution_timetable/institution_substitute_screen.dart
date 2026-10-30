import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_timetable.dart';
import '../../services/institution_timetable_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_substitute_controller.dart';
import 'institution_timetable_card.dart';

class InstitutionSubstituteScreen extends StatefulWidget {
  const InstitutionSubstituteScreen({super.key, required this.gateway, required this.timetable, required this.entry, this.initialDate});
  final InstitutionTimetableGateway gateway;
  final InstitutionTimetable timetable;
  final InstitutionTimetableEntry entry;
  final DateTime? initialDate;
  @override
  State<InstitutionSubstituteScreen> createState() => _InstitutionSubstituteScreenState();
}
class _InstitutionSubstituteScreenState extends State<InstitutionSubstituteScreen> with WidgetsBindingObserver {
  late InstitutionSubstituteController _state;
  final _form = GlobalKey<FormState>(), _notes = TextEditingController();
  final _scroll = ScrollController();
  late DateTime _date;
  int? _teacher;
  void _initialize() {
    _date = widget.initialDate ?? widget.timetable.nextDate(widget.entry, DateTime.now()) ??
      widget.timetable.academic.years.firstWhere((y) => y.id == widget.entry.yearId).start;
    _state = InstitutionSubstituteController(widget.gateway, widget.entry.id, _date)..reload();
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant InstitutionSubstituteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway || oldWidget.entry.identity != widget.entry.identity || oldWidget.initialDate != widget.initialDate) {
      _state.dispose(); _teacher = null; _notes.clear(); _initialize();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); _notes.dispose(); _scroll.dispose(); super.dispose(); }
  Future<void> _chooseDate() async {
    final controller = _state;
    if (controller.loading || controller.busy) return;
    final timetable = controller.snapshot?.timetable ?? widget.timetable;
    final entry = controller.snapshot?.entry ?? widget.entry;
    final year = timetable.academic.years.firstWhere((y) => y.id == entry.yearId);
    final initial = timetable.nextDate(entry, _date);
    if (initial == null) return;
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: year.start, lastDate: year.end,
      selectableDayPredicate: (d) => institutionWeekday(d) == entry.weekday);
    if (!mounted || date == null || !identical(controller, _state) || controller.busy || controller.loading) return;
    controller.dispose();
    setState(() {
      _date = date; _teacher = null;
      _state = InstitutionSubstituteController(widget.gateway, widget.entry.id, date)..reload();
    });
  }
  Future<void> _assign() async {
    final controller = _state, expected = _state.snapshot;
    final teacher = _teacher;
    if (!controller.canWrite || teacher == null || expected == null || !(_form.currentState?.validate() ?? false)) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) {
      final l = context.l10n;
      return AlertDialog(scrollable: true, title: Text(l.timetableAssign), content: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(expected.teachers[teacher]!), Text(MaterialLocalizations.of(context).formatMediumDate(_date)),
          Text(l.timetableReplaceNotice),
        ]), actions: [TextButton(key: const ValueKey('substitute-cancel'), onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(key: const ValueKey('substitute-confirm'), onPressed: () => Navigator.pop(context, true), child: Text(l.enrollmentConfirm))]);
    });
    if (confirmed == true && mounted && identical(controller, _state) && controller.canWrite &&
        identical(expected, controller.snapshot) && teacher == _teacher &&
        expected.teachers.containsKey(teacher) && _form.currentState?.validate() == true) {
      await controller.assign(teacher, _notes.text.isEmpty ? null : _notes.text);
      if (mounted && identical(controller, _state) && controller.saved && _scroll.hasClients) _scroll.jumpTo(0);
    }
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n, data = _state.snapshot;
    if (data != null && !data.teachers.containsKey(_teacher)) _teacher = null;
    final receipt = _state.receipt;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(l.timetableSubstitute),
        actions: [IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading || _state.busy ? null : _state.reload,
          icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: Form(key: _form, child: ListView(controller: _scroll, padding: const EdgeInsets.all(16), children: [
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          OutlinedButton(key: const ValueKey('substitute-date'), onPressed: _state.loading || _state.busy ? null : _chooseDate,
            child: Text(MaterialLocalizations.of(context).formatMediumDate(_date))),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(l, _state.error!))),
          if (_state.saved && receipt != null) Semantics(liveRegion: true, child: Card(key: const ValueKey('substitute-saved'),
            child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.enrollmentSaved), Text(receipt.teacherName), Text(MaterialLocalizations.of(context).formatMediumDate(receipt.date)),
            ])))),
          if (data != null) ...[
            InstitutionTimetableCard(timetable: data.timetable, entry: data.entry),
            Text(l.timetableReplaceNotice),
            if (data.teachers.isEmpty) Text(l.timetableNoSubstitutes),
            AcademicChoiceField(key: const ValueKey('substitute-teacher'), label: l.teacherAssignmentTeacher, options: data.teachers,
              value: _teacher, requiredMessage: l.academicRequired,
              onChanged: _state.canWrite ? (v) => setState(() => _teacher = v) : null),
            TextFormField(key: const ValueKey('substitute-notes'), controller: _notes, enabled: _state.canWrite,
              maxLines: null, decoration: InputDecoration(labelText: l.institutionAttendanceNote),
              validator: (v) => (v?.length ?? 0) <= 2000 ? null : l.institutionAttendanceNoteInvalid),
            FilledButton(key: const ValueKey('substitute-assign'), onPressed: _state.canWrite && _teacher != null ? _assign : null,
              child: Text(l.timetableAssign)),
          ],
        ])),
      ))),
    ));
  });
}
