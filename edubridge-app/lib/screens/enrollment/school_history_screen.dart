import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/enrollment/school_history.dart';
import '../../services/enrollment/school_history_repository.dart';
import '../../theme.dart';
import 'enrollment_labels.dart';
import 'enrollment_state.dart';

class SchoolHistoryScreen extends StatefulWidget {
  const SchoolHistoryScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.gateway,
  });
  final int childId;
  final String childName;
  final SchoolHistoryGateway? gateway;

  @override
  State<SchoolHistoryScreen> createState() => _SchoolHistoryScreenState();
}

class _SchoolHistoryScreenState extends State<SchoolHistoryScreen> {
  late final EnrollmentState<SchoolHistory> _state;

  @override
  void initState() {
    super.initState();
    _state = EnrollmentState(
      (widget.gateway ?? SchoolHistoryRepository(childId: widget.childId)).load,
    );
    _state.reload();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) {
      final l10n = context.l10n;
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          centerTitle: true,
          toolbarHeight: MediaQuery.textScalerOf(context).scale(100),
          title: Text(
            l10n.schoolHistoryTitle,
            textAlign: TextAlign.center,
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
        body: SafeArea(
          child: DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.childName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(l10n.schoolHistoryHint),
                if (_state.loading) const LinearProgressIndicator(),
                if (_state.error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(enrollmentFailureMessage(l10n, _state.error!)),
                  ),
                if (_state.snapshot != null) ...[
                  if (_state.snapshot!.records.isEmpty)
                    Text(l10n.schoolHistoryEmpty),
                  for (final record in _state.snapshot!.records)
                    Card(
                      key: ValueKey('school-history-${record.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              record.schoolName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(record.sectionLabel),
                            Text(switch (record.status) {
                              SchoolRecordStatus.active =>
                                l10n.schoolHistoryActive,
                              SchoolRecordStatus.closed =>
                                l10n.schoolHistoryClosed,
                              SchoolRecordStatus.transferred =>
                                l10n.schoolHistoryTransferred,
                            }),
                            Text(
                              '${l10n.schoolHistoryStart}: ${MaterialLocalizations.of(context).formatMediumDate(record.startedOn)}',
                            ),
                            if (record.endedOn != null)
                              Text(
                                '${l10n.schoolHistoryEnd}: ${MaterialLocalizations.of(context).formatMediumDate(record.endedOn!)}',
                              ),
                            if (record.transferredToId != null)
                              Text(
                                '${l10n.schoolHistoryDestination}: ${_state.snapshot!.records.firstWhere((r) => r.id == record.transferredToId).schoolName}',
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
