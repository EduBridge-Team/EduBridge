import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_plan_history.dart';
import '../../model/iep/iep_edit_source.dart';
import '../../model/iep/iep_version.dart';
import '../../services/iep/iep_history_repository.dart';
import '../../services/iep/iep_draft_repository.dart';
import '../../services/evaluations/evaluation_history_repository.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../theme.dart';
import '../enrollment/enrollment_state.dart';
import 'iep_labels.dart';
import 'iep_draft_editor_screen.dart';
import 'iep_plan_card.dart';
import 'iep_version_screen.dart';

class IepHistoryScreen extends StatefulWidget {
  const IepHistoryScreen({
    super.key,
    required this.childId,
    this.childName = '',
    this.gateway,
    this.evaluationGateway,
    this.saveGateway,
  });
  final int childId;
  final String childName;
  final IepHistoryGateway? gateway;
  final EvaluationHistoryGateway? evaluationGateway;
  final IepDraftGateway? saveGateway;
  @override
  State<IepHistoryScreen> createState() => _IepHistoryScreenState();
}

class _IepHistoryScreenState extends State<IepHistoryScreen>
    with WidgetsBindingObserver {
  late EnrollmentState<IepPlanHistory> _state;
  void _createState() {
    final childId = widget.childId;
    final gateway = widget.gateway ?? IepHistoryRepository(childId: childId);
    _state = EnrollmentState(() async {
      final data = await gateway.load();
      if (data.childId != childId)
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      return data;
    });
    _state.reload();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createState();
  }

  @override
  void didUpdateWidget(covariant IepHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.childId != oldWidget.childId ||
        widget.gateway != oldWidget.gateway) {
      _state.dispose();
      _createState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) {
      final l10n = context.l10n;
      final data = _state.snapshot;
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(
            l10n.iepTitle,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          actions: [
            IconButton(
              tooltip: l10n.enrollmentReload,
              onPressed: _state.loading ? null : _state.reload,
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
                    if (_state.error != EnrollmentFailure.session &&
                        _state.error != EnrollmentFailure.forbidden)
                      OutlinedButton.icon(
                        key: const ValueKey('iep-prepare-draft'),
                        onPressed: () async {
                          final saved = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => IepDraftEditorScreen(
                              childId: widget.childId,
                              childName: widget.childName,
                              evaluationGateway: widget.evaluationGateway,
                              saveGateway: widget.saveGateway,
                            ),
                          ),
                          );
                          if (mounted && saved == true) await _state.reload();
                        },
                        icon: const Icon(Icons.edit_note),
                        label: Text(l10n.iepComposeTitle),
                      ),
                    if (widget.childName.trim().isNotEmpty)
                      Text(
                        widget.childName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if (_state.loading) const LinearProgressIndicator(),
                    if (_state.error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          iepError(l10n, _state.error!),
                          key: const ValueKey('iep-error'),
                        ),
                      ),
                    if (data != null && data.plans.isEmpty && !_state.loading)
                      Text(l10n.iepEmpty),
                    if (data != null)
                      for (final plan in data.plans) ...[
                        IepPlanCard(
                          key: ValueKey('iep-plan-${plan.id}'),
                          plan: plan,
                          onOpen: (version) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => IepVersionScreen(
                                plan: plan,
                                version: version,
                                evaluationGateway: widget.evaluationGateway,
                              ),
                            ),
                          ),
                        ),
                        if (!plan.closed)
                          for (final version in plan.versions.where((v) => v.status == IepVersionStatus.draft && v.goals.isNotEmpty))
                            TextButton.icon(
                              key: ValueKey('iep-edit-copy-${version.id}'),
                              onPressed: _state.loading ? null : () async {
                                final source = IepEditSource.capture(plan, version);
                                final state = _state;
                                await state.reload();
                                if (!mounted || !identical(state, _state)) return;
                                final currentPlans = state.snapshot?.plans.where((p) => p.id == source.planId).toList();
                                if (currentPlans == null || currentPlans.length != 1) return;
                                final current = currentPlans.single;
                                final versions = current.versions.where((v) => v.id == source.versionId).toList();
                                if (versions.length != 1 || !source.matches(current, versions.single)) return;
                                final saved = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
                                  builder: (_) => IepDraftEditorScreen(childId: widget.childId,
                                    childName: widget.childName, editSource: source,
                                    evaluationGateway: widget.evaluationGateway),
                                ));
                                if (mounted && saved == true && identical(state, _state)) await state.reload();
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(Localizations.localeOf(context).languageCode == 'en'
                                ? 'Edit a temporary copy' : 'تعديل نسخة مؤقتة'),
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
