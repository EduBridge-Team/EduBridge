import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_draft.dart';
import '../../theme.dart';
import 'iep_draft_field.dart';

class IepGoalEditorScreen extends StatefulWidget {
  const IepGoalEditorScreen({
    super.key,
    required this.start,
    required this.end,
    this.initial,
  });
  final DateTime start, end;
  final IepDraftGoal? initial;
  @override
  State<IepGoalEditorScreen> createState() => _IepGoalEditorScreenState();
}

class _IepGoalEditorScreenState extends State<IepGoalEditorScreen> {
  final _form = GlobalKey<FormState>();
  final Map<String, String> _values = {};
  bool _dirty = false, _leaving = false, _asking = false;
  @override
  void initState() {
    super.initState();
    final goal = widget.initial;
    _values.addAll({
      'goal-title': goal?.title ?? '',
      'baseline': goal?.baseline.toString() ?? '',
      'target': goal?.target.toString() ?? '',
      'unit': goal?.unit ?? '',
      'method': goal?.method ?? '',
      'responsible': goal?.responsible ?? '',
      'goal-start': (goal?.start ?? widget.start).toIso8601String().substring(
        0,
        10,
      ),
      'goal-end': (goal?.end ?? widget.end).toIso8601String().substring(0, 10),
    });
  }

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

  void _accept() {
    if (!_form.currentState!.validate()) return;
    final goal = IepDraftGoal(
      title: _values['goal-title']!,
      baseline: parseIepMeasurement(_values['baseline']!)!,
      target: parseIepMeasurement(_values['target']!)!,
      unit: _values['unit']!,
      method: _values['method']!,
      responsible: _values['responsible']!,
      start: parseIepDraftDate(_values['goal-start']!)!,
      end: parseIepDraftDate(_values['goal-end']!)!,
    );
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, goal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? requiredText(String? v) =>
        v == null || v.trim().isEmpty ? l.academicRequired : null;
    String? measurement(String? v) =>
        parseIepMeasurement(v ?? '') == null ? l.iepComposeNumber : null;
    String? date(String? v) {
      final day = parseIepDraftDate(v ?? '');
      return day == null
          ? l.iepComposeDate
          : day.isBefore(widget.start) || day.isAfter(widget.end)
          ? l.iepComposeGoalDates
          : null;
    }

    Widget field(
      String name,
      String label, {
      String? Function(String?)? validator,
      bool numeric = false,
      bool multiline = false,
      String? hint,
    }) => IepDraftField(
      name: name,
      label: label,
      values: _values,
      validator: validator,
      numeric: numeric,
      multiline: multiline,
      hint: hint,
      onChanged: () => setState(() => _dirty = true),
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
            l.iepComposeGoal,
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
                      field(
                        'goal-title',
                        l.iepComposeGoalTitle,
                        validator: requiredText,
                        multiline: true,
                      ),
                      field(
                        'baseline',
                        l.iepBaseline,
                        validator: measurement,
                        numeric: true,
                      ),
                      field(
                        'target',
                        l.iepTarget,
                        validator: measurement,
                        numeric: true,
                      ),
                      field('unit', l.iepComposeUnit, validator: requiredText),
                      field(
                        'method',
                        l.iepMeasurement,
                        validator: requiredText,
                        multiline: true,
                      ),
                      field('responsible', l.iepResponsible),
                      field(
                        'goal-start',
                        l.academicStart,
                        validator: date,
                        hint: 'YYYY-MM-DD',
                      ),
                      field(
                        'goal-end',
                        l.academicEnd,
                        hint: 'YYYY-MM-DD',
                        validator: (v) {
                          final error = date(v);
                          if (error != null) return error;
                          final start = parseIepDraftDate(
                            _values['goal-start'] ?? '',
                          );
                          return start == null ||
                                  !parseIepDraftDate(v!)!.isAfter(start)
                              ? l.iepComposeGoalDates
                              : null;
                        },
                      ),
                      FilledButton(
                        key: const ValueKey('iep-accept-goal'),
                        onPressed: _accept,
                        child: Text(l.iepComposeUseGoal),
                      ),
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
