import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_draft.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../model/iep/iep_edit_source.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/iep/iep_draft_update_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

class IepDraftUpdateScreen extends StatefulWidget {
  const IepDraftUpdateScreen({super.key, required this.source, required this.draft, this.gateway});
  final IepEditSource source;
  final IepPlanDraft draft;
  final IepDraftUpdateGateway? gateway;
  @override
  State<IepDraftUpdateScreen> createState() => _IepDraftUpdateScreenState();
}

class _IepDraftUpdateScreenState extends State<IepDraftUpdateScreen> with WidgetsBindingObserver {
  late IepDraftUpdateGateway _gateway = widget.gateway ?? IepDraftUpdateRepository(source: widget.source);
  String _requestKey = newIepDraftRequestKey();
  IepDraftEditOptions? _options;
  EnrollmentFailure? _error;
  bool _loading = false, _busy = false, _locked = false, _saved = false;
  int _generation = 0;
  String label(String ar, String en) => Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _reload(); }
  @override
  void didUpdateWidget(covariant IepDraftUpdateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.draft != widget.draft ||
        oldWidget.gateway != widget.gateway) {
      // Never carry a permission, revision or idempotency key across a child/plan edit.
      _generation++;
      _gateway = widget.gateway ?? IepDraftUpdateRepository(source: widget.source);
      _requestKey = newIepDraftRequestKey();
      _loading = false;
      _busy = false;
      _locked = false;
      _saved = false;
      _options = null;
      _error = null;
      _reload();
    }
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _generation++; super.dispose(); }
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
  Future<void> _save() async {
    final options = _options, generation = _generation;
    if (options == null || _busy || _loading || _locked || _saved ||
        widget.draft.childId != widget.source.draft.childId ||
        !options.evaluationIds.contains(widget.draft.evaluationId)) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      content: Text(label('حفظ التعديلات على نفس المسودة؟ لا يعني ذلك اعتماد الخطة.', 'Save changes to this draft? This does not approve the plan.')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
        TextButton(key: const ValueKey('iep-update-confirm'), onPressed: () => Navigator.pop(context, true), child: Text(MaterialLocalizations.of(context).okButtonLabel))],
    ));
    if (!mounted || confirmed != true || generation != _generation || !identical(options, _options) || _busy || _loading || _locked || _saved) return;
    setState(() => _busy = true);
    try {
      await _gateway.update(widget.draft, options, _requestKey);
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
        title: Text(label('حفظ تعديل المسودة', 'Save draft changes'), softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload, onPressed: _busy || _loading || _saved ? null : _reload, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.draft.title, style: Theme.of(context).textTheme.titleLarge),
        Text(label('الحفظ يتطلب صلاحية تعديل ونسخة حديثة من الخدمة. عند تعذّر الحفظ، ارجعي للمحرر للاحتفاظ بمدخلاتك.',
          'Saving requires edit permission and a current server revision. Return to the editor to keep your entries if saving is unavailable.')),
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(context.l10n, _error!))),
        if (_locked) Text(label('راجعي سجل الخطة قبل أي محاولة أخرى؛ لن يُعاد إرسال التعديل من هذه الشاشة.', 'Review the plan history before another attempt; this screen will not resend the update.')),
        if (_saved) Text(label('تم تأكيد حفظ المسودة. لم يتم اعتماد الخطة.', 'Draft changes confirmed saved. The plan is not approved.')),
        if (!_saved) FilledButton(key: const ValueKey('iep-update-save'),
          onPressed: _busy || _loading || _locked || _options == null ||
              widget.draft.childId != widget.source.draft.childId ||
              !_options!.evaluationIds.contains(widget.draft.evaluationId) ? null : _save,
          child: Text(label('حفظ التعديلات', 'Save changes'))),
        if (_saved) TextButton(onPressed: () => Navigator.pop(context, true), child: Text(label('العودة للسجل', 'Return to history'))),
      ])),
    ),
  );
}
