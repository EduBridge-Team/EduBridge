import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_enrollment_history.dart';
import '../../services/institution_enrollment_history_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_enrollment_controller.dart';
import 'institution_transfer_dialog.dart';
import 'institution_withdrawal_dialog.dart';

class InstitutionEnrollmentHistoryScreen extends StatefulWidget {
  const InstitutionEnrollmentHistoryScreen({super.key, required this.gateway});
  final InstitutionEnrollmentHistoryGateway gateway;
  @override
  State<InstitutionEnrollmentHistoryScreen> createState() => _InstitutionEnrollmentHistoryScreenState();
}
class _InstitutionEnrollmentHistoryScreenState extends State<InstitutionEnrollmentHistoryScreen>
    with WidgetsBindingObserver {
  late InstitutionEnrollmentController _state;
  void _initialize() {
    _state = InstitutionEnrollmentController(widget.gateway)..reload();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }
  @override
  void didUpdateWidget(covariant InstitutionEnrollmentHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gateway != oldWidget.gateway) {
      _state.dispose();
      _initialize();
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
      final l = context.l10n;
      final data = _state.snapshot;
      final dates = MaterialLocalizations.of(context);
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(), title: Text(l.schoolHistoryTitle),
          actions: [IconButton(
            tooltip: l.enrollmentReload,
            onPressed: _state.loading || _state.busy ? null : _state.reload,
            icon: const Icon(Icons.refresh),
          )],
        ),
        body: RefreshIndicator(onRefresh: _state.reload,
          child: SafeArea(child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16), children: [
                if (_state.loading || _state.busy) const LinearProgressIndicator(),
                if (_state.saved) Semantics(liveRegion: true, child: Text(l.enrollmentSaved)),
                if (_state.error != null) Semantics(liveRegion: true,
                  child: Text(enrollmentFailureMessage(l, _state.error!))),
                if (data != null) ...[
                  Text(data.academic.school.name, style: Theme.of(context).textTheme.titleLarge),
                  if (data.records.isEmpty) Text(l.schoolHistoryEmpty),
                  for (final record in data.records) Card(
                    key: ValueKey('institution-enrollment-${record.id}'),
                    child: Padding(padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(record.childName, style: Theme.of(context).textTheme.titleMedium),
                        Text(data.sectionLabel(record.sectionId)),
                        Text(switch (record.status) {
                          InstitutionEnrollmentStatus.active => l.schoolHistoryActive,
                          InstitutionEnrollmentStatus.withdrawn => l.schoolHistoryClosed,
                          InstitutionEnrollmentStatus.transferred => l.schoolHistoryTransferred,
                        }),
                        if (record.start != null) Text('${l.schoolHistoryStart}: ${dates.formatMediumDate(record.start!)}'),
                        if (_state.supportsWithdrawal && record.status == InstitutionEnrollmentStatus.active)
                          OutlinedButton(
                            key: ValueKey('institution-withdraw-${record.id}'),
                            onPressed: !_state.canWrite ? null : () async {
                              final controller = _state;
                              final confirmed = await showDialog<bool>(context: context,
                                builder: (context) => InstitutionWithdrawalDialog(data: data, record: record));
                              if (confirmed == true && mounted && identical(controller, _state) && controller.canWrite) {
                                await controller.withdraw(record.id);
                              }
                            },
                            child: Text(l.institutionWithdrawalTitle),
                          ),
                        if (_state.supportsTransfer && data.transferTargets(record.id).isNotEmpty)
                          OutlinedButton(
                            key: ValueKey('institution-transfer-${record.id}'),
                            onPressed: !_state.canWrite ? null : () async {
                              final controller = _state;
                              final target = await showDialog<int>(context: context,
                                builder: (context) => InstitutionTransferDialog(data: data, record: record));
                              if (target != null && mounted && identical(controller, _state) && controller.canWrite) {
                                await controller.transfer(record.id, target);
                              }
                            },
                            child: Text(l.institutionTransferTitle),
                          ),
                        if (record.end != null) Text('${l.schoolHistoryEnd}: ${dates.formatMediumDate(record.end!)}'),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ))),
        ),
      );
    },
  );
}
