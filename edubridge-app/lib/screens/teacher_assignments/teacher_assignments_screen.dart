import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/teacher_assignment.dart';
import '../../services/schools/teacher_assignments_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'teacher_assignment_card.dart';
import 'teacher_assignment_create_screen.dart';
import 'teacher_assignments_controller.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key, this.gateway});
  final TeacherAssignmentsGateway? gateway;
  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen>
    with WidgetsBindingObserver {
  late TeacherAssignmentsController _controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TeacherAssignmentsController(
      widget.gateway ?? TeacherAssignmentsRepository(),
    );
    _controller.reload();
  }

  @override
  void didUpdateWidget(covariant TeacherAssignmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gateway != oldWidget.gateway) {
      _controller.dispose();
      _controller = TeacherAssignmentsController(
        widget.gateway ?? TeacherAssignmentsRepository(),
      )..reload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _remove(TeacherAssignment assignment) async {
    final controller = _controller;
    final data = controller.snapshot;
    if (!_controller.canWrite || data == null) return;
    final teacher = data.teachers.firstWhere(
      (v) => v.id == assignment.teacherId,
    );
    final subject = data.subjects.firstWhere(
      (v) => v.id == assignment.subjectId,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.teacherAssignmentRemove),
        content: SingleChildScrollView(
          child: Text(
            '${teacher.name}\n${data.sectionLabel(assignment.sectionId)}\n${subject.name}\n\n${context.l10n.teacherAssignmentRemoveNotice}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.enrollmentCancelAction),
          ),
          FilledButton(
            key: const ValueKey('assignment-confirm-remove'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.enrollmentConfirm),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true && identical(controller, _controller) &&
        identical(data, controller.snapshot)) {
      await controller.remove(assignment);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final l10n = context.l10n;
      final data = _controller.snapshot;
      final canAdd =
          _controller.canWrite &&
          data != null &&
          data.academic.sections.isNotEmpty &&
          data.teachers.any((v) => v.active) &&
          data.subjects.any((v) => v.active);
      return PopScope(canPop: !_controller.busy, child: Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(l10n.teacherAssignmentsTitle),
          actions: [
            IconButton(
              tooltip: l10n.enrollmentReload,
              onPressed: _controller.loading || _controller.busy
                  ? null
                  : _controller.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _controller.reload,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_controller.loading || _controller.busy)
                      const LinearProgressIndicator(),
                    if (_controller.saved)
                      Semantics(
                        liveRegion: true,
                        child: Text(l10n.enrollmentSaved),
                      ),
                    if (_controller.error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          enrollmentFailureMessage(l10n, _controller.error!),
                        ),
                      ),
                    if (data != null) ...[
                      Text(
                        data.academic.school.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('assignment-add'),
                        onPressed: canAdd
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TeacherAssignmentCreateScreen(
                                    controller: _controller,
                                  ),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.teacherAssignmentAdd),
                      ),
                      if (!canAdd && !_controller.loading && !_controller.busy)
                        Text(l10n.teacherAssignmentPrerequisite),
                      if (data.assignments.isEmpty)
                        Text(l10n.teacherAssignmentsEmpty),
                      for (final assignment in data.assignments)
                        TeacherAssignmentCard(
                          key: ValueKey('assignment-${assignment.id}'),
                          assignment: assignment,
                          catalog: data,
                          onRemove: _controller.canWrite
                              ? () => _remove(assignment)
                              : null,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
    },
  );
}
