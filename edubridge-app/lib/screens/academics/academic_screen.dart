import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/academic_catalog.dart';
import '../../services/schools/academic_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import '../curriculum/curriculum_screen.dart';
import '../../services/schools/curriculum_repository.dart';
import 'academic_controller.dart';
import 'academic_create_screen.dart';
import 'academic_sections_panel.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key, this.gateway, this.curriculumGateway});
  final AcademicGateway? gateway;
  final CurriculumGateway? curriculumGateway;
  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen>
    with WidgetsBindingObserver {
  late final AcademicController _controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AcademicController(widget.gateway ?? AcademicRepository());
    _controller.reload();
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

  Future<void> _open(AcademicKind kind) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AcademicCreateScreen(controller: _controller, kind: kind),
      ),
    );
  }

  Widget _add(AcademicKind kind, {bool enabled = true}) => OutlinedButton.icon(
    key: ValueKey('academic-add-${kind.name}'),
    onPressed: _controller.canWrite && enabled ? () => _open(kind) : null,
    icon: const Icon(Icons.add),
    label: Text(academicTitle(context, kind)),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final l10n = context.l10n;
      final data = _controller.snapshot;
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(l10n.academicTitle),
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
                    OutlinedButton.icon(
                      key: const ValueKey('open-school-curriculum'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CurriculumScreen(
                            gateway: widget.curriculumGateway,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(l10n.curriculumTitle),
                    ),
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
                        data.school.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        l10n.academicYears,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _add(AcademicKind.year),
                      if (data.years.isEmpty) Text(l10n.academicEmpty),
                      for (final year in data.years)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(year.name),
                                Text(
                                  '${MaterialLocalizations.of(context).formatMediumDate(year.start)} — ${MaterialLocalizations.of(context).formatMediumDate(year.end)}',
                                ),
                                if (year.current) Text(l10n.academicCurrent),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        l10n.academicGrades,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _add(AcademicKind.grade),
                      if (data.grades.isEmpty) Text(l10n.academicEmpty),
                      for (final grade in data.grades)
                        Card(child: ListTile(title: Text(grade.name))),
                      Text(
                        l10n.academicSections,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _add(
                        AcademicKind.section,
                        enabled:
                            data.years.isNotEmpty && data.grades.isNotEmpty,
                      ),
                      if (data.years.isEmpty || data.grades.isEmpty)
                        Text(l10n.academicSectionPrerequisite),
                      AcademicSectionsPanel(
                        key: ValueKey(data.school.id),
                        catalog: data,
                        enabled: _controller.canWrite,
                      ),
                    ],
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
