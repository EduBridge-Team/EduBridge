import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/schools/specialist_school_students.dart';
import '../../services/specialist_school_students_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';
import 'specialist_schools_labels.dart';
import 'specialist_school_students_screen.dart';

class SpecialistSchoolsScreen extends StatelessWidget {
  const SpecialistSchoolsScreen({super.key, this.gateway});
  final SpecialistSchoolStudentsGateway? gateway;
  static final SpecialistSchoolStudentsGateway _defaultGateway = SpecialistSchoolStudentsRepository();
  @override
  Widget build(BuildContext context) {
    final resolved = gateway ?? _defaultGateway;
    return _SchoolsBody(key: ObjectKey(resolved), gateway: resolved);
  }
}
class _SchoolsBody extends StatefulWidget {
  const _SchoolsBody({super.key, required this.gateway});
  final SpecialistSchoolStudentsGateway gateway;
  @override
  State<_SchoolsBody> createState() => _SchoolsBodyState();
}
class _SchoolsBodyState extends State<_SchoolsBody> with WidgetsBindingObserver {
  late final _state = EnrollmentState(widget.gateway.schools)..reload();
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<void> _open(SpecialistSchoolDirectory directory, SpecialistSchool school) async {
    if (!_state.canWrite || !identical(_state.snapshot, directory)) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      SpecialistSchoolStudentsScreen(specialistId: directory.specialistId, school: school, gateway: widget.gateway)));
    if (mounted) await _state.reload();
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = SpecialistSchoolsLabels(context);
    final data = _state.loading ? null : _state.snapshot;
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(l.schools),
      actions: [IconButton(tooltip: context.l10n.enrollmentReload,
        onPressed: _state.loading ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: RefreshIndicator(onRefresh: _state.reload, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
            Text(l.explanation),
            if (_state.loading) const LinearProgressIndicator(),
            if (_state.error != null) Text(enrollmentFailureMessage(context.l10n, _state.error!)),
            if (data != null && data.schools.isEmpty) Text(l.noSchools),
            if (data != null) for (final school in data.schools) OutlinedButton.icon(
              key: ValueKey('specialist-school-${school.id}'), onPressed: () => _open(data, school),
              icon: const Icon(Icons.school_outlined), label: Text(school.name)),
          ])),
      ))),
    );
  });
}

