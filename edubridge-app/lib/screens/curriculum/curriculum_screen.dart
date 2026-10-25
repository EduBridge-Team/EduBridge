import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/curriculum_draft.dart';
import '../../services/schools/curriculum_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'curriculum_controller.dart';
import 'curriculum_create_screen.dart';
import 'curriculum_records.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key, this.gateway});
  final CurriculumGateway? gateway;
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen>
    with WidgetsBindingObserver {
  late final CurriculumController _controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = CurriculumController(
      widget.gateway ?? CurriculumRepository(),
    );
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

  void _open(CurriculumKind kind) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          CurriculumCreateScreen(controller: _controller, kind: kind),
    ),
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
          title: Text(l10n.curriculumTitle),
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
                    if (data != null)
                      CurriculumRecords(
                        catalog: data,
                        onAddTerm: _controller.canWrite && data.years.isNotEmpty
                            ? () => _open(CurriculumKind.term)
                            : null,
                        onAddSubject: _controller.canWrite
                            ? () => _open(CurriculumKind.subject)
                            : null,
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
