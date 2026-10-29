import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/schools/specialist_school_students.dart';
import '../../services/specialist_school_students_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'specialist_school_students_controller.dart';
import 'specialist_schools_labels.dart';

class SpecialistSchoolStudentsScreen extends StatelessWidget {
  const SpecialistSchoolStudentsScreen({super.key, required this.specialistId, required this.school, required this.gateway});
  final int specialistId;
  final SpecialistSchool school;
  final SpecialistSchoolStudentsGateway gateway;
  @override
  Widget build(BuildContext context) => _RosterBody(
    key: ValueKey((specialistId, school, gateway)), specialistId: specialistId, school: school, gateway: gateway);
}
class _RosterBody extends StatefulWidget {
  const _RosterBody({super.key, required this.specialistId, required this.school, required this.gateway});
  final int specialistId;
  final SpecialistSchool school;
  final SpecialistSchoolStudentsGateway gateway;
  @override
  State<_RosterBody> createState() => _RosterBodyState();
}
class _RosterBodyState extends State<_RosterBody> with WidgetsBindingObserver {
  late SpecialistSchoolStudentsController _state = SpecialistSchoolStudentsController(widget.gateway, widget.specialistId, widget.school)..reload();
  final _search = TextEditingController();
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_state.busy) {
      setState(() {
        _state.dispose();
        _state = SpecialistSchoolStudentsController(widget.gateway, widget.specialistId, widget.school)..reload();
      });
    }
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _search.dispose(); _state.dispose(); super.dispose(); }
  Future<void> _follow(SpecialistSchoolRoster expected, SpecialistSchoolStudent student) async {
    final l = SpecialistSchoolsLabels(context);
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(l.follow), content: SingleChildScrollView(child: Text(
        '${widget.school.name}\n${student.name}\n${student.yearName} / ${student.sectionName}\n${l.explanation}')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(key: const ValueKey('specialist-follow-confirm'),
          onPressed: () => Navigator.pop(context, true), child: Text(l.confirm))]));
    if (confirmed == true && mounted) await _state.follow(expected, student);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = SpecialistSchoolsLabels(context);
    final data = _state.loading || _state.busy ? null : _state.snapshot;
    final query = _search.text.trim().toLowerCase();
    final students = data?.students.where((s) => s.name.toLowerCase().contains(query)).toList();
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(l.students, softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload,
          onPressed: _state.loading || _state.busy ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: RefreshIndicator(onRefresh: _state.reload, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
            Text(widget.school.name, style: Theme.of(context).textTheme.titleLarge),
            Text(l.explanation),
            TextField(key: const ValueKey('specialist-school-search'), controller: _search,
              decoration: InputDecoration(labelText: l.search, prefixIcon: const Icon(Icons.search)),
              onChanged: (_) => setState(() {})),
            if (_state.loading || _state.busy) const LinearProgressIndicator(),
            if (_state.saved) Text(context.l10n.enrollmentSaved),
            if (_state.error != null) Text(enrollmentFailureMessage(context.l10n, _state.error!)),
            if (data != null && students!.isEmpty) Text(query.isEmpty ? l.noStudents : l.noMatches),
            if (data != null) for (final student in students!) Card(
              key: ValueKey('specialist-school-student-${student.id}'),
              child: Padding(padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SelectableText(student.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('${student.yearName} / ${student.sectionName}'),
                  if (student.following) Text(l.following),
                  if (student.canFollow && !student.following) OutlinedButton.icon(
                    key: ValueKey('specialist-follow-${student.id}'),
                    onPressed: () => _follow(data, student), icon: const Icon(Icons.person_add_alt),
                    label: Text(l.follow)),
                ]))),
          ])),
      ))),
    ));
  });
}

