import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/iep/iep_goal_evidence.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/iep/iep_goal_evidence_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';
import 'iep_evidence_entry_card.dart';
import 'iep_evidence_labels.dart';
import 'iep_goal_card.dart';

class IepGoalEvidenceScreen extends StatelessWidget {
  const IepGoalEvidenceScreen({super.key, required this.source, this.gateway});
  final IepEvidenceSource source;
  final IepGoalEvidenceGateway? gateway;
  static final IepGoalEvidenceGateway _defaultGateway = IepGoalEvidenceRepository();
  @override
  Widget build(BuildContext context) {
    final resolved = gateway ?? _defaultGateway;
    return _EvidenceBody(key: ValueKey((source.childId, source.planId, source.goal, resolved)),
        source: source, gateway: resolved);
  }
}

class _EvidenceBody extends StatefulWidget {
  const _EvidenceBody({super.key, required this.source, required this.gateway});
  final IepEvidenceSource source;
  final IepGoalEvidenceGateway gateway;
  @override
  State<_EvidenceBody> createState() => _EvidenceBodyState();
}

class _EvidenceBodyState extends State<_EvidenceBody> with WidgetsBindingObserver {
  late final _state = EnrollmentState<IepEvidenceHistory>(_load)..reload();
  Future<IepEvidenceHistory> _load() async {
    final history = await widget.gateway.load(widget.source);
    if (!history.matches(widget.source)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    return history;
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
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
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final labels = IepEvidenceLabels(context);
    final history = _state.loading ? null : _state.snapshot;
    return Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(labels.title, softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload,
          onPressed: _state.loading ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: RefreshIndicator(onRefresh: _state.reload, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16), children: [
            IepGoalCard(goal: widget.source.goal),
            Text(labels.note),
            if (_state.loading) const LinearProgressIndicator(),
            if (_state.error != null)
              Text(enrollmentFailureMessage(context.l10n, _state.error!),
                  key: const ValueKey('iep-evidence-error')),
            if (history != null && history.entries.isEmpty) Text(labels.empty),
            if (history != null)
              for (final entry in history.entries)
                IepEvidenceEntryCard(key: ValueKey('iep-evidence-${entry.id}'),
                    entry: entry, unit: widget.source.goal.unit),
          ])),
      ))),
    );
  });
}

