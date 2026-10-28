import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../model/iep/iep_review.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/iep/iep_review_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

class IepReviewScreen extends StatefulWidget {
  const IepReviewScreen({super.key, required this.source, this.gateway});
  final IepReviewSource source;
  final IepReviewGateway? gateway;
  @override
  State<IepReviewScreen> createState() => _IepReviewScreenState();
}

class _IepReviewScreenState extends State<IepReviewScreen> with WidgetsBindingObserver {
  late final IepReviewGateway _gateway = widget.gateway ?? IepReviewRepository(source: widget.source);
  final _requestKey = newIepDraftRequestKey();
  IepReviewOptions? _options;
  EnrollmentFailure? _error;
  bool _loading = false, _busy = false, _locked = false, _saved = false;
  int _generation = 0;
  final _reason = TextEditingController();
  String actionLabel(IepReviewAction action) => switch (action) {
    IepReviewAction.submit => label('إرسال للمراجعة', 'Submit for review'),
    IepReviewAction.returnForChanges => label('إرجاع للتعديل', 'Return for changes'),
    IepReviewAction.approve => label('اعتماد الخطة', 'Approve plan'),
  };
  String label(String ar, String en) => Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _reload(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _reason.dispose(); _generation++; super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy && !_saved) _reload();
  }
  Future<void> _reload() async {
    if (_loading || _busy || _saved) return;
    final generation = ++_generation;
    setState(() { _loading = true; _options = null; _error = null; });
    try {
      final result = await _gateway.load();
      if (mounted && generation == _generation) setState(() => _options = result);
    } on EnrollmentApiException catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error.failure);
    } on Exception {
      if (mounted && generation == _generation) setState(() => _error = EnrollmentFailure.network);
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }
  Future<void> _act(IepReviewAction action) async {
    final options = _options, generation = _generation;
    if (options == null || _busy || _loading || _locked || _saved || !options.actions.contains(action)) return;
    if (action == IepReviewAction.returnForChanges && (_reason.text.trim().isEmpty || _reason.text.trim().length > 2000)) {
      setState(() => _error = EnrollmentFailure.validation); return;
    }
    final reason = _reason.text.trim();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(actionLabel(action)),
      content: Text(action == IepReviewAction.returnForChanges ? reason : label('تأكيد تنفيذ الإجراء على هذه النسخة؟', 'Confirm this action on this version?')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
        TextButton(key: const ValueKey('iep-review-confirm'), onPressed: () => Navigator.pop(context, true), child: Text(MaterialLocalizations.of(context).okButtonLabel))],
    ));
    if (!mounted || confirmed != true || generation != _generation || !identical(options, _options) || _busy || _loading || _locked || _saved) return;
    setState(() => _busy = true);
    try {
      await _gateway.act(action, options, _requestKey,
        reason: action == IepReviewAction.returnForChanges ? reason : '');
      if (mounted) setState(() { _saved = true; _options = null; });
    } on EnrollmentApiException catch (error) {
      if (mounted) setState(() {
        _error = error.failure; _options = null;
        _locked = error.failure == EnrollmentFailure.uncertain || error.failure == EnrollmentFailure.conflict;
      });
    } on Exception {
      if (mounted) setState(() { _error = EnrollmentFailure.uncertain; _options = null; _locked = true; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && !_saved,
    child: Scaffold(
      appBar: BrandAppBar(
        leading: BackButton(onPressed: _busy ? null : () => Navigator.pop(context, _saved)),
        title: Text(label('مراجعة خطة IEP', 'IEP review'), softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload, onPressed: _busy || _loading || _saved ? null : _reload, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.source.plan.title, style: Theme.of(context).textTheme.titleLarge),
        Text(label('تظهر الإجراءات التي تسمح بها الخدمة لهذه النسخة فقط.', 'Only actions authorized by the service for this version are available.')),
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(context.l10n, _error!))),
        if (_locked) Text(label('راجعي سجل الخطة قبل أي محاولة أخرى؛ لن يُعاد إرسال الإجراء من هذه الشاشة.', 'Review the plan history before another attempt; this screen will not resend the action.')),
        if (_saved) Text(label('تم تأكيد الإجراء. ارجعي للسجل لعرض الحالة الجديدة.', 'Action confirmed. Return to history to view the updated status.')),
        if (!_saved && _options?.actions.contains(IepReviewAction.returnForChanges) == true)
          TextField(key: const ValueKey('iep-review-reason'), controller: _reason,
            enabled: !_busy, minLines: 2, maxLines: null, maxLength: 2000,
            decoration: InputDecoration(label: Text(label('سبب الإرجاع', 'Return reason')))),
        if (!_loading && !_saved && _options != null && _options!.actions.isEmpty)
          Text(label('لا توجد إجراءات مراجعة متاحة لك لهذه النسخة.', 'No review actions are available to you for this version.')),
        if (!_saved)
          for (final action in IepReviewAction.values)
            if (_options?.actions.contains(action) == true)
              FilledButton(key: ValueKey('iep-review-${iepReviewActionName(action)}'),
                onPressed: _busy || _loading || _locked ? null : () => _act(action),
                child: Text(actionLabel(action))),
        if (_saved) TextButton(onPressed: () => Navigator.pop(context, true), child: Text(label('العودة للسجل', 'Return to history'))),
      ])),
    ),
  );
}
