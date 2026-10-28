import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/schools/teacher_section.dart';
import '../../services/teacher_sections_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';

typedef TeacherStudentListBuilder = Widget Function(List<Map<String, dynamic>> students, Future<void> Function() reload);
class TeacherSectionStudentsScreen extends StatelessWidget {
  const TeacherSectionStudentsScreen({super.key, required this.section, required this.gateway, required this.studentListBuilder});
  final TeacherSection section;
  final TeacherSectionsGateway gateway;
  final TeacherStudentListBuilder studentListBuilder;
  @override
  Widget build(BuildContext context) => _TeacherSectionStudentsBody(key: ValueKey((section, gateway)),
    section: section, gateway: gateway, studentListBuilder: studentListBuilder);
}
class _TeacherSectionStudentsBody extends StatefulWidget {
  const _TeacherSectionStudentsBody({super.key, required this.section, required this.gateway, required this.studentListBuilder});
  final TeacherSection section;
  final TeacherSectionsGateway gateway;
  final TeacherStudentListBuilder studentListBuilder;
  @override
  State<_TeacherSectionStudentsBody> createState() => _TeacherSectionStudentsBodyState();
}
class _TeacherSectionStudentsBodyState extends State<_TeacherSectionStudentsBody> with WidgetsBindingObserver {
  late final _state = EnrollmentState(() => widget.gateway.students(widget.section))..reload();
  String _query = '';
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _state.reload(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    String label(String ar, String en) => english ? en : ar;
    final roster = _state.loading ? null : _state.snapshot;
    final students = roster?.students.where((s) => (s['name'] as String).toLowerCase().contains(_query.trim().toLowerCase())).toList() ?? <Map<String, dynamic>>[];
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(widget.section.name, softWrap: true),
      actions: [IconButton(tooltip: context.l10n.enrollmentReload, onPressed: _state.loading ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${widget.section.schoolName} / ${widget.section.yearName}'),
          TextField(key: const ValueKey('teacher-section-students-search'),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), label: Text(label('البحث عن طالب', 'Search students'))),
            onChanged: (value) => setState(() => _query = value)),
        ])),
        if (_state.loading) const LinearProgressIndicator(),
        if (_state.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(enrollmentFailureMessage(context.l10n, _state.error!))),
        if (roster != null && students.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(label(
          _query.trim().isEmpty ? 'لا يوجد طلاب مسجلون في هذه الشعبة.' : 'لا يوجد طلاب مطابقون للبحث.',
          _query.trim().isEmpty ? 'No students enrolled in this section.' : 'No matching students.'))),
        if (roster != null && students.isNotEmpty) Expanded(child: RefreshIndicator(onRefresh: _state.reload,
          child: widget.studentListBuilder(students, _state.reload))),
      ])),
    );
  });
}
