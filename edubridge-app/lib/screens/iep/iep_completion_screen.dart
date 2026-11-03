import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_draft.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../model/iep/iep_edit_source.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/iep/iep_completion_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

/// Explicit author completion: makes the plan teacher-visible only after the
/// backend confirms a completed version and the specialist's history readback.
class IepCompletionScreen extends StatefulWidget {
  const IepCompletionScreen({
    super.key,
    required this.draft,
    this.childName = '',
    this.source,
    this.gateway,
    this.requestKey,
  });

  final IepPlanDraft draft;
  final String childName;
  final IepEditSource? source;
  final IepCompletionGateway? gateway;
  final String? requestKey;

  @override
  State<IepCompletionScreen> createState() => _IepCompletionScreenState();
}

class _IepCompletionScreenState extends State<IepCompletionScreen>
    with WidgetsBindingObserver {
  late IepCompletionGateway _gateway;
  late final String _requestKey = widget.requestKey ?? newIepDraftRequestKey();
  IepCompletionOptions? _options;
  EnrollmentFailure? _failure;
  bool _loading = false, _busy = false, _uncertain = false, _done = false;
  int _generation = 0;

  String _label(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : ar;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ??
        IepCompletionRepository(childId: widget.draft.childId);
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void didUpdateWidget(covariant IepCompletionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != widget.draft ||
        oldWidget.source != widget.source ||
        oldWidget.gateway != widget.gateway) {
      _gateway = widget.gateway ??
          IepCompletionRepository(childId: widget.draft.childId);
      _reload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy && !_done) _reload();
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reload() async {
    if (_busy || _done) return;
    final version = ++_generation;
    setState(() { _loading = true; _options = null; _failure = null; });
    try {
      final options = await _gateway.options();
      if (mounted && version == _generation) {
        setState(() => _options = options);
      }
    } on EnrollmentApiException catch (e) {
      if (mounted && version == _generation) setState(() => _failure = e.failure);
    } catch (_) {
      if (mounted && version == _generation) {
        setState(() => _failure = EnrollmentFailure.invalidResponse);
      }
    } finally {
      if (mounted && version == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    final expected = _options;
    if (expected == null || _loading || _busy || _uncertain || _done ||
        !expected.canComplete ||
        !expected.evaluationIds.contains(widget.draft.evaluationId)) return;
    final version = _generation;
    final confirmation = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: Text(_label('إتمام الخطة التعليمية', 'Complete educational plan')),
      content: Text(_label(
        'بعد التأكيد ستصبح الخطة متاحة للمعلم للعرض فقط، وستبقى محفوظة لدى المختص.',
        'Once confirmed, the teacher can read the plan. The specialist retains a saved copy.',
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false),
          child: Text(_label('إلغاء', 'Cancel'))),
        FilledButton(
          key: const ValueKey('iep-complete-confirm'),
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(_label('تأكيد', 'Confirm')),
        ),
      ],
    ));
    if (confirmation != true || !mounted || version != _generation ||
        !identical(_options, expected) || _busy || _loading) return;
    setState(() { _busy = true; _failure = null; _options = null; });
    try {
      final source = widget.source;
      if (source == null) {
        await _gateway.complete(widget.draft, expected, _requestKey);
      } else {
        await _gateway.completeExisting(source, widget.draft, expected, _requestKey);
      }
      if (mounted && version == _generation) setState(() => _done = true);
    } on EnrollmentApiException catch (e) {
      if (mounted && version == _generation) {
        setState(() {
          _failure = e.failure;
          _uncertain = e.failure == EnrollmentFailure.uncertain;
        });
      }
    } catch (_) {
      if (mounted && version == _generation) {
        setState(() {
          _failure = EnrollmentFailure.uncertain;
          _uncertain = true;
        });
      }
    } finally {
      if (mounted && version == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = !_busy && !_loading && !_done && !_uncertain &&
        _options?.canComplete == true &&
        _options?.evaluationIds.contains(widget.draft.evaluationId) == true;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: BrandAppBar(
          leading: BackButton(onPressed: _busy ? null : () => Navigator.pop(context, _done)),
          title: Text(_label('إتمام الخطة التعليمية', 'Complete educational plan')),
          actions: [
            IconButton(onPressed: _busy || _done || _uncertain || _loading ? null : _reload,
              icon: const Icon(Icons.refresh),
              tooltip: context.l10n.enrollmentReload),
          ],
        ),
        body: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (widget.childName.trim().isNotEmpty) Text(widget.childName,
                style: Theme.of(context).textTheme.titleLarge),
            SelectableText(widget.draft.title),
            const SizedBox(height: 12),
            Text(_label(
              'زر «تم» ينشر نسخة مكتملة فقط بعد تأكيد السيرفر. لا تُرسل الخطة إلى الوزارة.',
              'Done publishes only a server-confirmed completed plan. There is no Ministry submission.',
            )),
            if (_loading || _busy) const LinearProgressIndicator(),
            if (_done) ...[
              Text(_label('تم حفظ الخطة المكتملة لدى المختص وإتاحتها للمعلم.',
                  'Completed plan saved for the specialist and made visible to the teacher.'),
                key: const ValueKey('iep-complete-confirmed')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_label('العودة', 'Return')),
              ),
            ] else ...[
              if (_failure != null) Text(
                _uncertain
                  ? _label('قد تكون الخطة حُفظت. افحص السجل قبل إعادة المحاولة.',
                      'The plan may have been saved. Check history before retrying.')
                  : enrollmentFailureMessage(context.l10n, _failure!),
                key: const ValueKey('iep-complete-error'),
              ),
              if (_options != null && !_options!.canComplete)
                Text(_label('ليس لديك إذن لإتمام هذه الخطة.',
                    'You are not authorized to complete this plan.')),
              if (_options != null &&
                  !_options!.evaluationIds.contains(widget.draft.evaluationId))
                Text(_label('التقييم المرجعي غير متاح حاليًا.',
                    'The referenced evaluation is unavailable.')),
              FilledButton.icon(
                key: const ValueKey('iep-complete-submit'),
                onPressed: allowed ? _complete : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_label('تم', 'Done')),
              ),
            ],
          ]),
        ))),
      ),
    );
  }
}
