import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/academic_catalog.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/institution_academic_repository.dart';
import '../../services/institution_curriculum_repository.dart';
import '../../services/institution_teacher_assignments_repository.dart';
import '../../services/institution_enrollment_history_repository.dart';
import '../../services/institution_attendance_repository.dart';
import '../institution_attendance/institution_attendance_screen.dart';
import '../institution_enrollment/institution_enrollment_history_screen.dart';
import '../institution_teacher_assignments/institution_teacher_assignments_screen.dart';
import '../../services/schools/curriculum_repository.dart';
import '../curriculum/curriculum_screen.dart';
import '../../theme.dart';
import '../academics/academic_create_screen.dart';
import 'institution_academic_controller.dart';
import 'institution_academic_content.dart';

class InstitutionAcademicScreen extends StatefulWidget {
  const InstitutionAcademicScreen({
    super.key,
    required this.organizationSlug,
    required this.schoolId,
    this.gateway,
    this.curriculumGateway,
    this.teacherAssignmentsGateway,
    this.enrollmentHistoryGateway,
    this.attendanceGateway,
  });
  final String organizationSlug;
  final int schoolId;
  final InstitutionAcademicGateway? gateway;
  final CurriculumGateway? curriculumGateway;
  final InstitutionTeacherAssignmentsGateway? teacherAssignmentsGateway;
  final InstitutionEnrollmentHistoryGateway? enrollmentHistoryGateway;
  final InstitutionAttendanceGateway? attendanceGateway;
  @override
  State<InstitutionAcademicScreen> createState() =>
      _InstitutionAcademicScreenState();
}

class _InstitutionAcademicScreenState extends State<InstitutionAcademicScreen>
    with WidgetsBindingObserver {
  late InstitutionAcademicController _state;
  final _editorContextChanges = ValueNotifier<int>(0);
  void _initialize() {
    final slug = widget.organizationSlug, school = widget.schoolId;
    final gateway =
        widget.gateway ??
        InstitutionAcademicRepository(organizationSlug: slug, schoolId: school);
    _state = InstitutionAcademicController(
      gateway,
      organizationSlug: slug,
      schoolId: school,
    );
    _state.reload();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didUpdateWidget(covariant InstitutionAcademicScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolId != widget.schoolId ||
        oldWidget.organizationSlug != widget.organizationSlug ||
        oldWidget.gateway != widget.gateway) {
      _state.dispose();
      _initialize();
      // Disposing a controller ends its listeners. Rebuild any open editor
      // after this frame so its original, now-inactive context is visible.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editorContextChanges.value++;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    _editorContextChanges.dispose();
    super.dispose();
  }

  Future<void> _open(AcademicKind kind) async {
    final controller = _state;
    if (!controller.canWrite) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnimatedBuilder(
          animation: _editorContextChanges,
          builder: (context, _) =>
              AcademicCreateScreen(controller: controller, kind: kind),
        ),
      ),
    );
  }

  Future<void> _openAttendance() async {
    final records = _state.snapshot;
    if (records == null || _state.loading || _state.busy) return;
    final gateway = widget.attendanceGateway ?? InstitutionAttendanceRepository(
      organizationSlug: records.organizationSlug, organizationId: records.organizationId,
      schoolId: records.school.id);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => InstitutionAttendanceScreen(gateway: gateway)));
  }

  Future<void> _openEnrollmentHistory() async {
    final records = _state.snapshot;
    if (records == null || _state.loading || _state.busy) return;
    final gateway = widget.enrollmentHistoryGateway ?? InstitutionEnrollmentHistoryRepository(
      organizationSlug: records.organizationSlug,
      organizationId: records.organizationId,
      schoolId: records.school.id,
    );
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => InstitutionEnrollmentHistoryScreen(gateway: gateway),
    ));
  }

  Future<void> _openTeachers() async {
    final controller = _state;
    final records = controller.snapshot;
    if (!controller.canWrite || records == null) return;
    final gateway = widget.teacherAssignmentsGateway ?? InstitutionTeacherAssignmentsRepository(
      organizationSlug: records.organizationSlug,
      organizationId: records.organizationId,
      schoolId: records.school.id,
    );
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => InstitutionTeacherAssignmentsScreen(gateway: gateway),
    ));
    if (mounted && identical(controller, _state)) await controller.reload();
  }

  Future<void> _openCurriculum() async {
    final controller = _state;
    final records = controller.snapshot;
    if (!controller.canWrite || records == null) return;
    final gateway = widget.curriculumGateway ?? InstitutionCurriculumRepository(
      organizationSlug: records.organizationSlug,
      schoolId: records.school.id,
      organizationId: records.organizationId,
    );
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CurriculumScreen(gateway: gateway),
    ));
    if (mounted && identical(controller, _state)) await controller.reload();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) {
      final l = context.l10n;
      final data = _state.snapshot;
      final error = switch (_state.error) {
        null => null,
        EnrollmentFailure.session => l.enrollmentSession,
        EnrollmentFailure.forbidden => l.institutionAcademicForbidden,
        EnrollmentFailure.invalidResponse => l.institutionAcademicInvalid,
        _ => l.institutionAcademicFailed,
      };
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(
            l.institutionAcademicTitle,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          actions: [
            IconButton(
              tooltip: l.enrollmentReload,
              onPressed: _state.loading || _state.busy ? null : _state.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _state.reload,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (data != null) OutlinedButton.icon(
                      key: const ValueKey('institution-open-enrollment-history'),
                      onPressed: _state.loading || _state.busy ? null : _openEnrollmentHistory,
                      icon: const Icon(Icons.history),
                      label: Text(l.schoolHistoryTitle),
                    ),
                    if (data != null) OutlinedButton.icon(
                      key: const ValueKey('institution-open-attendance'),
                      onPressed: _state.loading || _state.busy ? null : _openAttendance,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(l.institutionAttendanceTitle),
                    ),
                    if (data != null && _state.supportsCreation) ...[
                      OutlinedButton.icon(
                        key: const ValueKey('institution-open-teacher-assignments'),
                        onPressed: _state.canWrite ? _openTeachers : null,
                        icon: const Icon(Icons.groups_outlined),
                        label: Text(l.teacherAssignmentsTitle),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('institution-open-curriculum'),
                        onPressed: _state.canWrite ? _openCurriculum : null,
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(l.curriculumTitle),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final kind in AcademicKind.values)
                            OutlinedButton.icon(
                              key: ValueKey('institution-add-${kind.name}'),
                              onPressed:
                                  _state.canWrite &&
                                      (kind != AcademicKind.section ||
                                          (data.years.isNotEmpty &&
                                              data.grades.isNotEmpty))
                                  ? () => _open(kind)
                                  : null,
                              icon: const Icon(Icons.add),
                              label: Text(academicTitle(context, kind)),
                            ),
                        ],
                      ),
                      if (data.years.isEmpty || data.grades.isEmpty)
                        Text(l.academicSectionPrerequisite),
                    ],
                    if (_state.loading || _state.busy)
                      const LinearProgressIndicator(),
                    if (_state.saved)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          l.enrollmentSaved,
                          key: const ValueKey('institution-academic-saved'),
                        ),
                      ),
                    if (error != null)
                      Semantics(liveRegion: true, child: Text(error)),
                    if (data != null)
                      InstitutionAcademicContent(
                        key: ValueKey((
                          widget.organizationSlug,
                          widget.schoolId,
                        )),
                        records: data,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
