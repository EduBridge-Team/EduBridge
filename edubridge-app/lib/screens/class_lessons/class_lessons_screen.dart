import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/class_lessons/class_lesson_catalog.dart';
import '../../services/class_lesson_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';
import 'class_lesson_results.dart';
import 'class_assignment_screen.dart';
import '../../model/class_lessons/class_lesson_result.dart';
import '../class_lesson_results/class_result_screen.dart';

class ClassLessonsScreen extends StatefulWidget {
  const ClassLessonsScreen({super.key, this.gateway});
  final ClassLessonGateway? gateway;
  @override
  State<ClassLessonsScreen> createState() => _ClassLessonsScreenState();
}
class _ClassLessonsScreenState extends State<ClassLessonsScreen> with WidgetsBindingObserver {
  late EnrollmentState<ClassLessonCatalog> _state;
  int? _sectionId;
  void _initialize() {
    final gateway = widget.gateway ?? ClassLessonRepository();
    _state = EnrollmentState(gateway.load)..reload();
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant ClassLessonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) { _state.dispose(); _sectionId = null; _initialize(); }
  }
  Future<void> _reload() async {
    setState(() => _sectionId = null);
    await _state.reload();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final state = _state, data = state.snapshot;
    final sections = !state.loading ? data?.sections ?? <ClassLessonSection>[] : <ClassLessonSection>[];
    final selected = sections.where((s) => s.id == _sectionId).toList();
    final english = Localizations.localeOf(context).languageCode == 'en';
    String label(String ar, String en) => english ? en : ar;
    return Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(label('دروس الشُّعب', 'Class lessons'), softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload, onPressed: state.loading ? null : _reload, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _reload, child: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900), child: ListView(padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(), children: [
            Text(label('دروس الشعبة ونتائج الطلاب والهدف المرتبط بكل طالب عند توفرها.',
              'Section lessons, student results and each student’s linked goal when available.')),
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(context.l10n, state.error!))),
            if (!state.loading && data != null && sections.isEmpty) Text(label('لا توجد شُعب متاحة لهذا الحساب.', 'No sections available for this account.')),
            AcademicChoiceField(key: const ValueKey('class-lesson-section'),
              label: label('الشعبة', 'Section'), requiredMessage: context.l10n.academicRequired,
              value: _sectionId, options: {for (final s in sections) s.id: '${s.schoolName} / ${s.yearName} / ${s.name}'},
              onChanged: state.loading ? null : (id) {
                if (!mounted || !identical(state, _state) || state.loading || !identical(data, state.snapshot) ||
                    !sections.any((s) => s.id == id)) return;
                setState(() => _sectionId = id);
              }),
            if (selected.length == 1) ...[
              OutlinedButton.icon(key: const ValueKey('class-lesson-assign'), icon: const Icon(Icons.playlist_add),
                label: Text(label('إسناد درس للشعبة', 'Assign class lesson')),
                onPressed: () async {
                  await Navigator.of(context).push<bool>(MaterialPageRoute(
                    builder: (_) => ClassAssignmentScreen(section: selected.single)));
                  if (mounted) await _reload();
                }),
              ClassLessonResults(section: selected.single, onRecord: (lesson, student) async {
                await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ClassResultScreen(
                  source: ClassResultSource(section: selected.single, lesson: lesson, student: student))));
                if (mounted) await _reload();
              }),
            ],
          ]),
      )))),
    );
  });
}
