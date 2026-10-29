import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/institutions/school_specialist_assignments.dart';
import '../../services/school_specialist_assignments_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'school_specialists_controller.dart';
import 'school_specialists_labels.dart';

class SchoolSpecialistsScreen extends StatelessWidget {
  const SchoolSpecialistsScreen({super.key, required this.gateway});
  final SchoolSpecialistAssignmentsGateway gateway;
  @override
  Widget build(BuildContext context) => _SchoolSpecialistsBody(
    key: ObjectKey(gateway), gateway: gateway);
}
class _SchoolSpecialistsBody extends StatefulWidget {
  const _SchoolSpecialistsBody({super.key, required this.gateway});
  final SchoolSpecialistAssignmentsGateway gateway;
  @override
  State<_SchoolSpecialistsBody> createState() => _SchoolSpecialistsBodyState();
}
class _SchoolSpecialistsBodyState extends State<_SchoolSpecialistsBody> with WidgetsBindingObserver {
  late final _state = SchoolSpecialistsController(widget.gateway)..reload();
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<bool> _confirm(String title, String body) async {
    final l = SchoolSpecialistsLabels(context);
    return await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: SingleChildScrollView(child: Text(body)),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(key: const ValueKey('specialist-confirm'),
          onPressed: () => Navigator.pop(context, true), child: Text(l.confirm))])) == true;
  }
  Future<void> _add(SchoolSpecialistAssignments expected) async {
    final l = SchoolSpecialistsLabels(context);
    final choices = expected.eligible.entries.where((e) => expected.canAdd(e.key)).toList();
    final selected = await showDialog<int>(context: context, builder: (context) => SimpleDialog(
      title: Text(l.choose), children: [for (final item in choices)
        SimpleDialogOption(key: ValueKey('specialist-option-${item.key}'),
          onPressed: () => Navigator.pop(context, item.key), child: Text(item.value))]));
    if (!mounted || !_state.canWrite || !identical(_state.snapshot, expected) || selected == null) return;
    final date = MaterialLocalizations.of(context).formatFullDate(expected.effectiveOn);
    if (await _confirm(l.add, '${expected.eligible[selected]}\n${l.effective}: $date\n${l.scope}') && mounted) {
      await _state.assign(expected, selected);
    }
  }
  Future<void> _end(SchoolSpecialistAssignments expected, SchoolSpecialistAssignment assignment) async {
    final l = SchoolSpecialistsLabels(context);
    final date = MaterialLocalizations.of(context).formatFullDate(expected.effectiveOn);
    if (await _confirm(l.end, '${assignment.name}\n${l.effective}: $date\n${l.endEffect}') && mounted) {
      await _state.end(expected, assignment);
    }
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = SchoolSpecialistsLabels(context), dates = MaterialLocalizations.of(context);
    final data = _state.loading || _state.busy ? null : _state.snapshot;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(l.title, softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload,
          onPressed: _state.loading || _state.busy ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: RefreshIndicator(onRefresh: _state.reload, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
            Text(l.scope),
            if (_state.loading || _state.busy) const LinearProgressIndicator(),
            if (_state.saved) Text(context.l10n.enrollmentSaved),
            if (_state.error != null) Text(enrollmentFailureMessage(context.l10n, _state.error!)),
            if (data != null) ...[
              SelectableText(data.schoolName, style: Theme.of(context).textTheme.titleLarge),
              if (data.canAssign) OutlinedButton.icon(key: const ValueKey('specialist-add'),
                onPressed: data.eligible.keys.any(data.canAdd) ? () => _add(data) : null,
                icon: const Icon(Icons.person_add_alt), label: Text(l.add)),
              if (data.canAssign && !data.eligible.keys.any(data.canAdd)) Text(l.noEligible),
              if (data.assignments.isEmpty) Text(l.empty),
              for (final assignment in data.assignments) Card(key: ValueKey('specialist-assignment-${assignment.id}'),
                child: Padding(padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SelectableText(assignment.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(assignment.active ? l.active : l.ended),
                    Text(dates.formatFullDate(assignment.startsOn)),
                    if (assignment.endedOn != null) Text(dates.formatFullDate(assignment.endedOn!)),
                    if (assignment.active && assignment.canEnd) OutlinedButton(
                      key: ValueKey('specialist-end-${assignment.id}'),
                      onPressed: () => _end(data, assignment), child: Text(l.end)),
                  ]))),
            ],
          ])),
      ))),
    ));
  });
}

