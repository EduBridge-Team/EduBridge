import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/evaluations/evaluation_record.dart';
import '../../model/iep/iep_draft.dart';
import '../../model/iep/iep_edit_source.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../services/iep/iep_draft_repository.dart';
import '../../services/iep/iep_draft_update_repository.dart';
import '../../services/iep/iep_completion_repository.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/evaluations/evaluation_history_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_state.dart';
import '../enrollment/enrollment_labels.dart';
import '../evaluation_history/evaluation_history_labels.dart';
import 'iep_draft_field.dart';
import 'iep_draft_preview_screen.dart';
import 'iep_evaluation_reference.dart';
import 'iep_draft_goal_card.dart';
import 'iep_goal_editor_screen.dart';

/// Authoring remains temporary until an explicitly confirmed server save.
class IepDraftEditorScreen extends StatelessWidget {
  const IepDraftEditorScreen({
    super.key,
    required this.childId,
    this.childName = '',
    this.evaluationGateway,
    this.saveGateway,
    this.completionGateway,
    this.editSource,
  });
  final int childId;
  final String childName;
  final EvaluationHistoryGateway? evaluationGateway;
  final IepDraftGateway? saveGateway;
  final IepCompletionGateway? completionGateway;
  final IepEditSource? editSource;
  @override
  Widget build(BuildContext context) => _IepDraftEditorBody(
    key: ValueKey((childId, evaluationGateway, saveGateway, completionGateway, editSource)),
    childId: childId,
    childName: childName,
    evaluationGateway: evaluationGateway,
    saveGateway: saveGateway,
    completionGateway: completionGateway,
    editSource: editSource,
  );
}

class _IepDraftEditorBody extends StatefulWidget {
  const _IepDraftEditorBody({
    super.key,
    required this.childId,
    required this.childName,
    this.evaluationGateway,
    this.saveGateway,
    this.completionGateway,
    this.editSource,
  });
  final int childId;
  final String childName;
  final EvaluationHistoryGateway? evaluationGateway;
  final IepDraftGateway? saveGateway;
  final IepCompletionGateway? completionGateway;
  final IepEditSource? editSource;
  @override
  State<_IepDraftEditorBody> createState() => _IepDraftEditorScreenState();
}

class _IepDraftEditorScreenState extends State<_IepDraftEditorBody>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _saveRequestKey = newIepDraftRequestKey();
  final _completionRequestKey = newIepDraftRequestKey();
  final Map<String, String> _values = {};
  final List<IepDraftGoal> _goals = [];
  late EnrollmentState<EvaluationHistory> _evaluations;
  int? _evaluationId;
  IepPlanDraft? _checked;
  String? _goalError;
  bool _dirty = false, _leaving = false, _asking = false;
  bool _busy = false, _writeLocked = false;
  EnrollmentFailure? _writeError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final source = widget.editSource;
    if (source != null) {
      final draft = source.draft;
      if (draft.childId != widget.childId) throw ArgumentError('Foreign IEP draft');
      String day(DateTime date) => date.toIso8601String().substring(0, 10);
      _values.addAll({'title': draft.title, 'summary': draft.summary,
        'start': day(draft.start), 'end': day(draft.end), 'review': day(draft.reviewOn),
        'accommodations': draft.accommodations.join('\n')});
      _goals.addAll(draft.goals);
      _evaluationId = draft.evaluationId;
    }

    final childId = widget.childId;
    final gateway =
        widget.evaluationGateway ??
        EvaluationHistoryRepository(childId: childId);
    _evaluations = EnrollmentState(() async {
      final data = await gateway.load();
      if (data.childId != childId) {
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      }
      return data;
    });
    _evaluations.addListener(_evaluationChanged);
    _evaluations.reload();
  }

  void _evaluationChanged() {
    if (mounted) setState(() => _checked = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _evaluations.reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _evaluations.removeListener(_evaluationChanged);
    _evaluations.dispose();
    super.dispose();
  }

  void _changed() => setState(() {
    _dirty = true;
    _checked = null;
    _goalError = null;
    if (!_writeLocked) _writeError = null;
  });
  Future<void> _back() async {
    if (_asking || _busy || _leaving) return;
    _asking = true;
    final l = context.l10n;
    final leave =
        !_dirty ||
        await confirmIepDiscard(
          context,
          l.iepComposeDiscardNotice,
          l.iepComposeDiscard,
          l.cancel,
        );
    _asking = false;
    if (!mounted || !leave) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _editGoal([int? index]) async {
    final start = parseIepDraftDate(_values['start'] ?? '');
    final end = parseIepDraftDate(_values['end'] ?? '');
    if (start == null || end == null || !end.isAfter(start)) {
      _form.currentState!.validate();
      setState(() => _goalError = context.l10n.iepComposePlanDates);
      return;
    }
    final goal = await Navigator.of(context).push<IepDraftGoal>(
      MaterialPageRoute(
        builder: (_) => IepGoalEditorScreen(
          start: start,
          end: end,
          initial: index == null ? null : _goals[index],
        ),
      ),
    );
    if (!mounted || goal == null) return;
    if (index == null) {
      _goals.add(goal);
    } else {
      _goals[index] = goal;
    }
    _changed();
  }

  Future<void> _removeGoal(int index) async {
    final l = context.l10n;
    final remove = await confirmIepDiscard(
      context,
      l.iepComposeRemoveGoal,
      l.delete,
      l.cancel,
    );
    if (!mounted || !remove) return;
    _goals.removeAt(index);
    _changed();
  }

  IepPlanDraft? _verify() {
    final validFields = _form.currentState!.validate();
    final start = parseIepDraftDate(_values['start'] ?? '');
    final end = parseIepDraftDate(_values['end'] ?? '');
    final validGoals =
        _goals.isNotEmpty &&
        start != null &&
        end != null &&
        _goals.every((g) => !g.start.isBefore(start) && !g.end.isAfter(end));
    setState(() {
      _checked = null;
      _goalError = validGoals ? null : context.l10n.iepComposeGoalsRequired;
      if (validFields &&
          validGoals &&
          !_evaluations.loading &&
          _evaluations.snapshot?.records.any((r) => r.id == _evaluationId) ==
              true) {
        _checked = IepPlanDraft(
          childId: widget.childId,
          evaluationId: _evaluationId!,
          title: _values['title']!,
          start: start,
          end: end,
          reviewOn: parseIepDraftDate(_values['review']!)!,
          goals: _goals,
          summary: _values['summary'] ?? '',
          accommodations: (_values['accommodations'] ?? '')
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        );
      }
    });
    return _checked;
  }

  Future<void> _preview(IepPlanDraft draft) async {
    if (!identical(_checked, draft)) return;
    final childName = widget.childName;
    final gateway = widget.evaluationGateway;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IepDraftPreviewScreen(
          draft: draft,
          childName: childName,
          evaluationGateway: gateway,
        ),
      ),
    );
    if (mounted) await _evaluations.reload();
  }

  /// The two visible actions share the same validation and submit exactly once.
  /// A confirmed server readback (not a local optimistic flag) is required.
  Future<void> _submit({required bool complete}) async {
    if (_busy || _writeLocked || _leaving || _evaluations.loading ||
        _evaluations.error != null || _evaluations.snapshot == null) return;
    final draft = _verify();
    if (draft == null) return;
    setState(() { _busy = true; _writeError = null; });
    try {
      if (complete) {
        final gateway = widget.completionGateway ??
            IepCompletionRepository(childId: widget.childId);
        final options = await gateway.options();
        if (options.childId != widget.childId ||
            !options.evaluationIds.contains(draft.evaluationId)) {
          throw const EnrollmentApiException(EnrollmentFailure.conflict);
        }
        if (!options.canComplete) {
          throw const EnrollmentApiException(EnrollmentFailure.forbidden);
        }
        if (widget.editSource == null) {
          await gateway.complete(draft, options, _completionRequestKey);
        } else {
          await gateway.completeExisting(
              widget.editSource!, draft, options, _completionRequestKey);
        }
      } else if (widget.editSource != null) {
        final gateway = IepDraftUpdateRepository(source: widget.editSource!);
        final options = await gateway.load();
        if (!options.evaluationIds.contains(draft.evaluationId)) {
          throw const EnrollmentApiException(EnrollmentFailure.conflict);
        }
        await gateway.update(draft, options, _saveRequestKey);
      } else {
        final gateway = widget.saveGateway ??
            IepDraftRepository(childId: widget.childId);
        final options = await gateway.options();
        if (options.childId != widget.childId ||
            !options.evaluationIds.contains(draft.evaluationId)) {
          throw const EnrollmentApiException(EnrollmentFailure.conflict);
        }
        if (!options.canCreate) {
          throw const EnrollmentApiException(EnrollmentFailure.forbidden);
        }
        final receipt = await gateway.create(draft, _saveRequestKey);
        if (!receipt.matches(draft)) {
          throw const EnrollmentApiException(EnrollmentFailure.uncertain);
        }
      }
      if (!mounted) return;
      setState(() { _dirty = false; _leaving = true; _writeError = null; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } on EnrollmentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _writeError = error.failure;
        _writeLocked = error.failure == EnrollmentFailure.uncertain;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _writeError = EnrollmentFailure.uncertain;
        _writeLocked = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewCurrent() async {
    if (_busy || _evaluations.loading || _evaluations.error != null) return;
    final draft = _verify();
    if (draft != null) await _preview(draft);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canSubmit = !_busy && !_writeLocked && !_evaluations.loading &&
        _evaluations.error == null && _evaluations.snapshot != null &&
        _evaluations.snapshot!.records.isNotEmpty;
    String? requiredText(String? v) =>
        v == null || v.trim().isEmpty ? l.academicRequired : null;
    String? date(String? v) =>
        parseIepDraftDate(v ?? '') == null ? l.iepComposeDate : null;
    Widget field(
      String name,
      String label, {
      String? Function(String?)? validator,
      bool multiline = false,
      String? hint,
    }) => IepDraftField(
      name: name,
      label: label,
      values: _values,
      onChanged: _changed,
      validator: validator,
      multiline: multiline,
      hint: hint,
    );
    final records = _evaluations.snapshot?.records ?? <EvaluationRecord>[];
    final options = {
      for (final r in records)
        r.id:
            '${evaluationRecordTitle(l, r)} — ${r.createdAt.toIso8601String().substring(0, 10)} (#${r.id})',
    };
    final doneButton = FilledButton.icon(
      key: const ValueKey('iep-complete-plan'),
      onPressed: canSubmit ? () => _submit(complete: true) : null,
      icon: const Icon(Icons.check_circle_outline),
      label: Text(Localizations.localeOf(context).languageCode == 'en'
          ? 'Done' : 'تم'),
    );
    final draftButton = OutlinedButton.icon(
      key: const ValueKey('iep-open-server-save'),
      onPressed: canSubmit ? () => _submit(complete: false) : null,
      icon: const Icon(Icons.save_outlined),
      label: Text(Localizations.localeOf(context).languageCode == 'en'
          ? 'Save as draft' : 'حفظ كمسودة'),
    );
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: BrandAppBar(
          leading: BackButton(onPressed: _back),
          title: Text(
            l.iepComposeTitle,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          actions: [
            IconButton(
              key: const ValueKey('iep-preview-draft'),
              onPressed: canSubmit ? _previewCurrent : null,
              tooltip: l.iepComposePreview,
              icon: const Icon(Icons.preview_outlined),
            ),
            IconButton(
              key: const ValueKey('iep-reload-evaluations'),
              onPressed: _busy || _evaluations.loading
                  ? null : _evaluations.reload,
              tooltip: l.enrollmentReload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AbsorbPointer(
                  absorbing: _busy,
                  child: Form(
                    key: _form,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.childName.trim().isNotEmpty)
                        Text(
                          widget.childName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      Text(
                        widget.editSource == null ? l.iepComposeNotice
                          : (Localizations.localeOf(context).languageCode == 'en'
                            ? 'Edit the saved draft, then choose Save as draft or Done. Leaving without saving discards changes.'
                            : 'عدّل المسودة المحفوظة، ثم اختر حفظ كمسودة أو تم. مغادرة المحرر دون حفظ تلغي التغييرات.'),
                        key: const ValueKey('iep-unsaved-notice'),
                      ),
                      const SizedBox(height: 16),
                      if (_evaluations.loading) const LinearProgressIndicator(),
                      if (_evaluations.error != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            evaluationHistoryError(l, _evaluations.error!),
                          ),
                        ),
                      if (!_evaluations.loading &&
                          _evaluations.error == null &&
                          records.isEmpty)
                        Text(l.iepComposeNoEvaluations),
                      AcademicChoiceField(
                        key: const ValueKey('iep-choose-evaluation'),
                        label: l.iepComposeEvaluation,
                        options: options,
                        value: _evaluationId,
                        requiredMessage: l.academicRequired,
                        onChanged: _evaluations.loading
                            ? null
                            : (id) {
                                if (!options.containsKey(id)) return;
                                _evaluationId = id;
                                _changed();
                              },
                      ),
                      const SizedBox(height: 16),
                      if (!_evaluations.loading &&
                          options.containsKey(_evaluationId))
                        IepEvaluationReference(
                          key: ValueKey((
                            widget.childId,
                            _evaluationId,
                            widget.evaluationGateway,
                          )),
                          childId: widget.childId,
                          evaluationId: _evaluationId!,
                          gateway: widget.evaluationGateway,
                        ),
                      field(
                        'title',
                        l.iepComposePlanTitle,
                        validator: requiredText,
                        multiline: true,
                      ),
                      field(
                        'start',
                        l.academicStart,
                        validator: date,
                        hint: 'YYYY-MM-DD',
                      ),
                      field(
                        'end',
                        l.academicEnd,
                        hint: 'YYYY-MM-DD',
                        validator: (v) {
                          final error = date(v);
                          if (error != null) return error;
                          final start = parseIepDraftDate(
                            _values['start'] ?? '',
                          );
                          return start == null ||
                                  !parseIepDraftDate(v!)!.isAfter(start)
                              ? l.iepComposePlanDates
                              : null;
                        },
                      ),
                      field(
                        'review',
                        l.iepReviewDate,
                        hint: 'YYYY-MM-DD',
                        validator: (v) {
                          final error = date(v);
                          if (error != null) return error;
                          final start = parseIepDraftDate(
                            _values['start'] ?? '',
                          );
                          return start == null ||
                                  parseIepDraftDate(v!)!.isBefore(start)
                              ? l.iepComposeReviewDate
                              : null;
                        },
                      ),
                      field('summary', l.iepComposeSummary, multiline: true),
                      field(
                        'accommodations',
                        l.iepAccommodations,
                        multiline: true,
                        hint: l.iepComposeAccommodationsHint,
                      ),
                      Text(
                        l.iepGoals,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      for (var i = 0; i < _goals.length; i++)
                        IepDraftGoalCard(
                          key: ValueKey('iep-draft-goal-$i'),
                          goal: _goals[i],
                          onEdit: () => _editGoal(i),
                          onRemove: () => _removeGoal(i),
                        ),
                      OutlinedButton.icon(
                        key: const ValueKey('iep-add-goal'),
                        onPressed: _editGoal,
                        icon: const Icon(Icons.add),
                        label: Text(l.iepComposeGoal),
                      ),
                      if (_goalError != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _goalError!,
                            key: const ValueKey('iep-draft-goals-error'),
                          ),
                        ),
                      if (_busy) const LinearProgressIndicator(),
                      if (_writeError != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _writeLocked
                                ? (Localizations.localeOf(context).languageCode == 'en'
                                    ? 'Save status is uncertain. Check the child plan history before trying again.'
                                    : 'حالة الحفظ غير مؤكدة. راجع سجل خطط الطفل قبل إعادة المحاولة.')
                                : enrollmentFailureMessage(l, _writeError!),
                            key: const ValueKey('iep-submit-error'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      LayoutBuilder(builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 450;
                        return Flex(
                          direction: narrow ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: narrow
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.center,
                          children: [
                            narrow ? doneButton : Expanded(child: doneButton),
                            SizedBox(height: narrow ? 10 : 0,
                                width: narrow ? 0 : 12),
                            narrow ? draftButton : Expanded(child: draftButton),
                          ],
                        );
                      }),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
