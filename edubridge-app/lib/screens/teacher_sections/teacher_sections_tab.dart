import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/schools/teacher_section.dart';
import '../../services/teacher_sections_repository.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';
import 'teacher_section_students_screen.dart';

class TeacherSectionsTab extends StatefulWidget {
  const TeacherSectionsTab({super.key, this.gateway, required this.studentListBuilder});
  final TeacherSectionsGateway? gateway;
  final TeacherStudentListBuilder studentListBuilder;
  @override
  State<TeacherSectionsTab> createState() => _TeacherSectionsTabState();
}
class _TeacherSectionsTabState extends State<TeacherSectionsTab> with WidgetsBindingObserver {
  late EnrollmentState<TeacherSectionCatalog> _state;
  late TeacherSectionsGateway _gateway;
  String _query = '';
  final _search = TextEditingController();
  void _initialize() {
    _gateway = widget.gateway ?? TeacherSectionsRepository();
    _state = EnrollmentState(_gateway.sections)..reload();
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant TeacherSectionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) { _state.dispose(); _query = ''; _search.clear(); _initialize(); }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _state.reload(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    String label(String ar, String en) => english ? en : ar;
    final state = _state, snapshot = state.snapshot, gateway = _gateway;
    final sections = state.loading ? <TeacherSection>[] : snapshot?.sections ?? <TeacherSection>[];
    final filtered = sections.where((s) => '${s.label} ${s.subjects.values.join(' ')}'.toLowerCase().contains(_query.trim().toLowerCase())).toList();
    return RefreshIndicator(onRefresh: state.reload, child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: Text(context.l10n.academicSections, style: Theme.of(context).textTheme.headlineSmall)),
            IconButton(tooltip: context.l10n.enrollmentReload, onPressed: state.loading ? null : state.reload, icon: const Icon(Icons.refresh))]),
          TextField(key: const ValueKey('teacher-sections-search'), controller: _search,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), label: Text(label('البحث عن شعبة', 'Search sections'))),
            onChanged: (value) => setState(() => _query = value)),
          const SizedBox(height: 12),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null) Text(enrollmentFailureMessage(context.l10n, state.error!)),
          if (!state.loading && snapshot != null && sections.isEmpty) Text(label('لا توجد شُعب مكلّف بها حاليًا.', 'No sections currently assigned to you.')),
          if (!state.loading && sections.isNotEmpty && filtered.isEmpty) Text(label('لا توجد شُعب مطابقة للبحث.', 'No matching sections.')),
          for (final section in filtered) Card(child: ListTile(
            key: ValueKey('teacher-section-${section.id}'), leading: const Icon(Icons.groups_outlined),
            title: Text(section.name), subtitle: Text('${section.schoolName}\n${section.yearName}${section.subjects.isEmpty ? '' : '\n${section.subjects.values.join('، ')}'}'),
            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right), onTap: () async {
              if (!identical(state, _state) || state.loading || !identical(snapshot, state.snapshot)) return;
              await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TeacherSectionStudentsScreen(
                section: section, gateway: gateway, studentListBuilder: widget.studentListBuilder)));
              if (mounted && identical(state, _state)) await state.reload();
            },
          )),
        ])),
      ),
    ));
  });
}
