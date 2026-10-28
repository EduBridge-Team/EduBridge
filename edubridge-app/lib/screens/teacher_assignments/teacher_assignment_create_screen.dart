import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/teacher_assignment.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import 'teacher_assignments_controller.dart';

class TeacherAssignmentCreateScreen extends StatefulWidget {
  const TeacherAssignmentCreateScreen({super.key, required this.controller});
  final TeacherAssignmentsController controller;
  @override
  State<TeacherAssignmentCreateScreen> createState() =>
      _TeacherAssignmentCreateScreenState();
}

class _TeacherAssignmentCreateScreenState
    extends State<TeacherAssignmentCreateScreen> {
  final _form = GlobalKey<FormState>();
  int? _teacher, _section, _subject, _school;
  bool _attempted = false;
  bool get _canWrite =>
      widget.controller.canWrite &&
      widget.controller.snapshot?.schoolId == _school;
  TeacherAssignmentDraft get _draft => TeacherAssignmentDraft(
    teacherId: _teacher ?? 0,
    sectionId: _section ?? 0,
    subjectId: _subject ?? 0,
  );
  @override
  void initState() {
    super.initState();
    _school = widget.controller.snapshot?.schoolId;
    widget.controller.addListener(_syncCatalog);
  }

  void _syncCatalog() {
    final data = widget.controller.snapshot;
    if (data == null) return;
    _school ??= data.schoolId;
    if (!data.teachers.any((v) => v.id == _teacher && v.active))
      _teacher = null;
    if (!data.subjects.any((v) => v.id == _subject && v.active))
      _subject = null;
    if (!data.academic.sections.any((v) => v.id == _section)) _section = null;
  }

  @override
  void didUpdateWidget(covariant TeacherAssignmentCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncCatalog);
      widget.controller.addListener(_syncCatalog);
      _teacher = null;
      _section = null;
      _subject = null;
      _school = widget.controller.snapshot?.schoolId;
      _attempted = false;
      _syncCatalog();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncCatalog);
    super.dispose();
  }

  void _selectTeacher(int value) {
    if (_canWrite &&
        widget.controller.snapshot!.teachers.any(
          (v) => v.id == value && v.active,
        )) {
      setState(() => _teacher = value);
    }
  }

  void _selectSection(int value) {
    if (_canWrite &&
        widget.controller.snapshot!.academic.sections.any(
          (v) => v.id == value,
        )) {
      setState(() => _section = value);
    }
  }

  void _selectSubject(int value) {
    if (_canWrite &&
        widget.controller.snapshot!.subjects.any(
          (v) => v.id == value && v.active,
        )) {
      setState(() => _subject = value);
    }
  }

  Future<void> _save() async {
    if (!_canWrite) return;
    setState(() => _attempted = true);
    if (!_form.currentState!.validate() ||
        !widget.controller.snapshot!.canCreate(_draft))
      return;
    final controller = widget.controller;
    final saved = await controller.create(_draft);
    if (mounted && identical(controller, widget.controller) && saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final l10n = context.l10n;
      final controller = widget.controller;
      final data = controller.snapshot;
      return PopScope(
        canPop: !controller.busy,
        child: Scaffold(
          appBar: BrandAppBar(
            leading: BackButton(
              onPressed: () {
                if (!controller.busy) Navigator.of(context).maybePop();
              },
            ),
            title: Text(l10n.teacherAssignmentAdd),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (data != null) ...[
                          AcademicChoiceField(
                            key: const ValueKey('assignment-teacher'),
                            label: l10n.teacherAssignmentTeacher,
                            options: {
                              for (final item in data.teachers.where(
                                (v) => v.active,
                              ))
                                item.id: item.name,
                            },
                            value: _teacher,
                            requiredMessage: l10n.academicRequired,
                            onChanged: _canWrite ? (value) {
                              if (identical(controller, widget.controller) &&
                                  identical(data, controller.snapshot)) _selectTeacher(value);
                            } : null,
                          ),
                          AcademicChoiceField(
                            key: const ValueKey('assignment-section'),
                            label: l10n.enrollmentSection,
                            options: {
                              for (final item in data.academic.sections)
                                item.id: data.sectionLabel(item.id),
                            },
                            value: _section,
                            requiredMessage: l10n.academicRequired,
                            onChanged: _canWrite ? (value) {
                              if (identical(controller, widget.controller) &&
                                  identical(data, controller.snapshot)) _selectSection(value);
                            } : null,
                          ),
                          AcademicChoiceField(
                            key: const ValueKey('assignment-subject'),
                            label: l10n.subject,
                            options: {
                              for (final item in data.subjects.where(
                                (v) => v.active,
                              ))
                                item.id: item.name,
                            },
                            value: _subject,
                            requiredMessage: l10n.academicRequired,
                            onChanged: _canWrite ? (value) {
                              if (identical(controller, widget.controller) &&
                                  identical(data, controller.snapshot)) _selectSubject(value);
                            } : null,
                          ),
                          if (_attempted && !data.canCreate(_draft))
                            Semantics(
                              liveRegion: true,
                              child: Text(l10n.teacherAssignmentInvalid),
                            ),
                          if (data.schoolId != _school)
                            Text(
                              enrollmentFailureMessage(
                                l10n,
                                EnrollmentFailure.forbidden,
                              ),
                            ),
                        ],
                        if (_attempted && controller.error != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              enrollmentFailureMessage(l10n, controller.error!),
                            ),
                          ),
                        if (controller.busy) const LinearProgressIndicator(),
                        if (_attempted &&
                            !controller.canWrite &&
                            !controller.busy)
                          TextButton(
                            onPressed: controller.reload,
                            child: Text(l10n.enrollmentReload),
                          ),
                        FilledButton(
                          key: const ValueKey('assignment-save'),
                          onPressed: _canWrite ? _save : null,
                          child: Text(l10n.academicSave),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
