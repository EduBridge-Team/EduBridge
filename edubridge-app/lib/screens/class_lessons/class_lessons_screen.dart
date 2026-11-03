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
import '../add_lesson/add_lesson_screen.dart';
import '../interactive_lesson/interactive_lesson_starter_library.dart';

class ClassLessonsScreen extends StatefulWidget {
  const ClassLessonsScreen({super.key, this.gateway, this.types = const []});
  final ClassLessonGateway? gateway;
  /// Existing teacher lesson form accepts disability labels already loaded by the dashboard.
  final List types;
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
  Future<void> _createOrdinaryLesson() async {
    final lesson = await Navigator.of(context).push<Map>(
      MaterialPageRoute<Map>(builder: (_) => AddLessonScreen(
        types: widget.types, studentsOnly: true)),
    );
    if (!mounted || lesson == null) return;
    final english = Localizations.localeOf(context).languageCode == 'en';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(english
        ? 'Lesson saved. Class assignment is a separate step.'
        : 'تم حفظ الدرس. إسناده للشعبة خطوة مستقلة.'),
    ));
    await _state.reload();
  }

  Future<void> _openInteractiveTemplates() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) =>
          const InteractiveLessonStarterLibrary()),
    );
  }

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
            Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  key: const ValueKey('class-lesson-create-ordinary'),
                  icon: const Icon(Icons.note_add_outlined),
                  label: Text(label('إضافة درس عادي', 'Add regular lesson')),
                  onPressed: _createOrdinaryLesson,
                ),
                OutlinedButton.icon(
                  key: const ValueKey('class-lesson-interactive-templates'),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: Text(label('القوالب التفاعلية', 'Interactive templates')),
                  onPressed: _openInteractiveTemplates,
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                label('إنشاء الدرس لا يعني إسناده تلقائيًا للشعبة.',
                  'Creating a lesson does not automatically assign it to the class.'),
                style: TextStyle(color: JisrColors.of(context).muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
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
