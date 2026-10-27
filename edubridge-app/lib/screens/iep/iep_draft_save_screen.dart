import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_draft.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/iep/iep_draft_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'iep_draft_save_controller.dart';

class IepDraftSaveScreen extends StatelessWidget {
  const IepDraftSaveScreen({super.key, required this.draft, this.childName = '', this.gateway, this.requestKey});
  final IepPlanDraft draft;
  final String childName;
  final IepDraftGateway? gateway;
  final String? requestKey;
  @override
  Widget build(BuildContext context) => _IepDraftSaveBody(
    key: ValueKey((draft, gateway, requestKey)), requestKey: requestKey, draft: draft, childName: childName,
    gateway: gateway ?? IepDraftRepository(childId: draft.childId),
  );
}

class _IepDraftSaveBody extends StatefulWidget {
  const _IepDraftSaveBody({super.key, required this.draft, required this.childName, required this.gateway, this.requestKey});
  final IepPlanDraft draft;
  final String childName;
  final IepDraftGateway gateway;
  final String? requestKey;
  @override
  State<_IepDraftSaveBody> createState() => _IepDraftSaveBodyState();
}

class _IepDraftSaveBodyState extends State<_IepDraftSaveBody> with WidgetsBindingObserver {
  late final IepDraftSaveController _state;
  bool _leaving = false;
  @override
  void initState() {
    super.initState();
    _state = IepDraftSaveController(widget.draft, widget.gateway, requestKey: widget.requestKey)..reload();
    WidgetsBinding.instance.addObserver(this);
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
  void _back() {
    if (_state.busy || _leaving) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, _state.receipt);
    });
  }
  Future<void> _save() async {
    final expected = _state.snapshot;
    if (!_state.canCreate || expected == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(dialogContext.l10n.iepSaveTitle),
      content: Text(dialogContext.l10n.iepSaveConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.l10n.cancel)),
        FilledButton(key: const ValueKey('iep-confirm-save'),
          onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.l10n.save)),
      ],
    ));
    if (confirmed == true && mounted) await _state.create(expected);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n, receipt = _state.receipt;
    final options = _state.snapshot;
    final dates = MaterialLocalizations.of(context);
    return PopScope(canPop: _leaving, onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    }, child: Scaffold(
      appBar: BrandAppBar(leading: BackButton(onPressed: _back), title: Text(l.iepSaveTitle, softWrap: true, overflow: TextOverflow.visible)),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (widget.childName.trim().isNotEmpty) Text(widget.childName),
          SelectableText(widget.draft.title),
          Text('${l.academicStart}: ${dates.formatMediumDate(widget.draft.start)}'),
          Text('${l.academicEnd}: ${dates.formatMediumDate(widget.draft.end)}'),
          Text(l.iepSaveNotice),
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (receipt != null) ...[
            Semantics(liveRegion: true, child: Text(l.iepSaveSuccess, key: const ValueKey('iep-server-saved'))),
            Text('${l.iepVersionNumber}: ${receipt.version.number}'),
            Text(l.iepDraft),
            FilledButton(onPressed: _back, child: Text(l.iepTitle)),
          ] else ...[
            if (_state.needsReview)
              Semantics(liveRegion: true, child: Text(l.iepSaveUncertain, key: const ValueKey('iep-save-uncertain')))
            else if (_state.error != null)
              Semantics(liveRegion: true, child: Text(
                _state.error == EnrollmentFailure.unavailable ? l.iepSaveUnavailable : enrollmentFailureMessage(l, _state.error!),
                key: const ValueKey('iep-save-error'),
              )),
            if (options != null && !options.canCreate) Text(l.iepSaveForbidden),
            if (options != null && options.canCreate && !options.evaluationIds.contains(widget.draft.evaluationId))
              Text(l.iepSaveReferenceUnavailable),
            OutlinedButton(key: const ValueKey('iep-reload-save-options'),
              onPressed: _state.loading || _state.busy ? null : _state.reload, child: Text(l.enrollmentReload)),
            FilledButton(key: const ValueKey('iep-save-to-server'),
              onPressed: _state.canCreate ? _save : null, child: Text(l.iepSaveTitle)),
          ],
        ]),
      ))),
    ));
  });
}
