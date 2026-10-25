import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/evaluations/evaluation_record.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/evaluations/evaluation_history_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_state.dart';
import 'evaluation_history_card.dart';
import 'evaluation_history_labels.dart';
import 'evaluation_record_screen.dart';

class EvaluationHistoryScreen extends StatefulWidget {
  const EvaluationHistoryScreen({
    super.key,
    required this.childId,
    this.childName = '',
    this.gateway,
  });
  final int childId;
  final String childName;
  final EvaluationHistoryGateway? gateway;
  @override
  State<EvaluationHistoryScreen> createState() =>
      _EvaluationHistoryScreenState();
}

class _EvaluationHistoryScreenState extends State<EvaluationHistoryScreen>
    with WidgetsBindingObserver {
  late EnrollmentState<EvaluationHistory> _state;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createState();
  }

  void _createState() {
    final gateway =
        widget.gateway ?? EvaluationHistoryRepository(childId: widget.childId);
    _state = EnrollmentState(() async {
      final data = await gateway.load();
      if (data.childId != widget.childId) {
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      }
      return data;
    });
    _state.reload();
  }

  @override
  void didUpdateWidget(covariant EvaluationHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId ||
        oldWidget.gateway != widget.gateway) {
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
          title: Text(l10n.evaluationHistoryTitle),
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
                          evaluationHistoryError(l10n, _state.error!),
                          key: const ValueKey('evaluation-history-error'),
                        ),
                      ),
                    if (data != null && data.records.isEmpty && !_state.loading)
                      Text(
                        l10n.noRecordedEvaluation,
                        key: const ValueKey('evaluation-history-empty'),
                      ),
                    if (data != null)
                      for (final record in data.records)
                        EvaluationHistoryCard(
                          key: ValueKey('evaluation-record-${record.id}'),
                          record: record,
                          onOpen: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  EvaluationRecordScreen(record: record),
                            ),
                          ),
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
