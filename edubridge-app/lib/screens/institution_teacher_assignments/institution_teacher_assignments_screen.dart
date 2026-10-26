import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/teacher_assignment.dart';
import '../../services/institution_teacher_assignments_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_teacher_assignments_controller.dart';

class InstitutionTeacherAssignmentsScreen extends StatefulWidget {
  const InstitutionTeacherAssignmentsScreen({super.key, required this.gateway});
  final InstitutionTeacherAssignmentsGateway gateway;
  @override
  State<InstitutionTeacherAssignmentsScreen> createState() =>
      _InstitutionTeacherAssignmentsScreenState();
}

class _InstitutionTeacherAssignmentsScreenState
    extends State<InstitutionTeacherAssignmentsScreen> with WidgetsBindingObserver {
  late final InstitutionTeacherAssignmentsController _state;
  final _form = GlobalKey<FormState>();
  int? _teacher, _section, _subject;
  bool _invalid = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = InstitutionTeacherAssignmentsController(widget.gateway)..reload();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }
  Future<void> _save() async {
    if (!_state.canWrite || !_form.currentState!.validate()) return;
    final draft = TeacherAssignmentDraft(
      teacherId: _teacher!, sectionId: _section!, subjectId: _subject!,
    );
    if (_state.snapshot?.canCreate(draft) != true) {
      setState(() => _invalid = true);
      return;
    }
    final saved = await _state.create(draft);
    if (mounted && saved) setState(() {
      _teacher = null;
      _section = null;
      _subject = null;
      _invalid = false;
    });
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) {
      final l = context.l10n, data = _state.snapshot;
      return PopScope(
        canPop: !_state.busy,
        child: Scaffold(
          appBar: BrandAppBar(
            leading: BackButton(onPressed: _state.busy ? () {} : null),
            title: Text(l.teacherAssignmentsTitle),
            actions: [IconButton(
              tooltip: l.enrollmentReload,
              onPressed: _state.loading || _state.busy ? null : _state.reload,
              icon: const Icon(Icons.refresh),
            )],
          ),
          body: RefreshIndicator(
            onRefresh: _state.reload,
            child: SafeArea(child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_state.loading || _state.busy) const LinearProgressIndicator(),
                  if (_state.saved) Semantics(liveRegion: true, child: Text(l.enrollmentSaved)),
                  if (_state.error != null) Semantics(liveRegion: true,
                    child: Text(enrollmentFailureMessage(l, _state.error!))),
                  if (data != null) ...[
                    Text(data.academic.school.name, style: Theme.of(context).textTheme.titleLarge),
                    Form(key: _form, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AcademicChoiceField(
                          key: const ValueKey('institution-assignment-teacher'),
                          label: l.teacherAssignmentTeacher, options: data.teachers,
                          value: _teacher, requiredMessage: l.academicRequired,
                          onChanged: _state.canWrite ? (v) => setState(() => _teacher = v) : null,
                        ),
                        AcademicChoiceField(
                          key: const ValueKey('institution-assignment-section'),
                          label: l.enrollmentSection,
                          options: {for (final v in data.academic.sections) v.id: data.sectionLabel(v.id)},
                          value: _section, requiredMessage: l.academicRequired,
                          onChanged: _state.canWrite ? (v) => setState(() => _section = v) : null,
                        ),
                        AcademicChoiceField(
                          key: const ValueKey('institution-assignment-subject'),
                          label: l.subject,
                          options: {for (final v in data.academic.curriculum.subjects.where((v) => v.active)) v.id: v.name},
                          value: _subject, requiredMessage: l.academicRequired,
                          onChanged: _state.canWrite ? (v) => setState(() => _subject = v) : null,
                        ),
                        if (_invalid) Text(l.teacherAssignmentInvalid),
                        FilledButton(
                          key: const ValueKey('institution-assignment-save'),
                          onPressed: _state.canWrite ? _save : null,
                          child: Text(l.teacherAssignmentAdd),
                        ),
                      ],
                    )),
                    if (data.assignments.isEmpty) Text(l.academicEmpty),
                    for (final item in data.assignments) Card(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(item.teacherName),
                        Text(data.sectionLabel(item.draft.sectionId)),
                        Text(data.academic.curriculum.subjects.firstWhere((v) => v.id == item.draft.subjectId).name),
                      ]),
                    )),
                  ],
                ],
              ),
            ))),
          ),
        ),
      );
    },
  );
}
