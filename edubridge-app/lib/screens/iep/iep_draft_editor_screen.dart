import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/evaluations/evaluation_record.dart';
import '../../model/iep/iep_draft.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/evaluations/evaluation_history_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_state.dart';
import '../evaluation_history/evaluation_history_labels.dart';
import 'iep_draft_field.dart';
import 'iep_draft_preview_screen.dart';
import 'iep_evaluation_reference.dart';
import 'iep_draft_goal_card.dart';
import 'iep_goal_editor_screen.dart';

/// Preparation only: no write gateway, persistence or approval is implied.
class IepDraftEditorScreen extends StatelessWidget {
  const IepDraftEditorScreen({
    super.key,
    required this.childId,
    this.childName = '',
    this.evaluationGateway,
  });
  final int childId;
  final String childName;
  final EvaluationHistoryGateway? evaluationGateway;
  @override
  Widget build(BuildContext context) => _IepDraftEditorBody(
    key: ValueKey((childId, evaluationGateway)),
    childId: childId,
    childName: childName,
    evaluationGateway: evaluationGateway,
  );
}

class _IepDraftEditorBody extends StatefulWidget {
  const _IepDraftEditorBody({
    super.key,
    required this.childId,
    required this.childName,
    this.evaluationGateway,
  });
  final int childId;
  final String childName;
  final EvaluationHistoryGateway? evaluationGateway;
  @override
  State<_IepDraftEditorBody> createState() => _IepDraftEditorScreenState();
}

class _IepDraftEditorScreenState extends State<_IepDraftEditorBody>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final Map<String, String> _values = {};
  final List<IepDraftGoal> _goals = [];
  late EnrollmentState<EvaluationHistory> _evaluations;
  int? _evaluationId;
  IepPlanDraft? _checked;
  String? _goalError;
  bool _dirty = false, _leaving = false, _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  });
  Future<void> _back() async {
    if (_asking) return;
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

  void _verify() {
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final checked = _checked;
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
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                        l.iepComposeNotice,
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
                      OutlinedButton.icon(
                        key: const ValueKey('iep-reload-evaluations'),
                        onPressed: _evaluations.loading
                            ? null
                            : _evaluations.reload,
                        icon: const Icon(Icons.refresh),
                        label: Text(l.enrollmentReload),
                      ),
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
                      FilledButton(
                        key: const ValueKey('iep-verify-draft'),
                        onPressed: _evaluations.loading || records.isEmpty
                            ? null
                            : _verify,
                        child: Text(l.iepComposeVerify),
                      ),
                      if (checked != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l.iepComposeChecked,
                            key: const ValueKey('iep-draft-checked'),
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const ValueKey('iep-preview-draft'),
                          onPressed: () => _preview(checked),
                          icon: const Icon(Icons.preview_outlined),
                          label: Text(l.iepComposePreview),
                        ),
                      ],
                    ],
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
