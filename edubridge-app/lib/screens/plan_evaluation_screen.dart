import '../l10n/l10n.dart';
// lib/screens/plan_evaluation_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';

class PlanEvaluationScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int planId;

  const PlanEvaluationScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.planId,
  });

  @override
  State<PlanEvaluationScreen> createState() => _PlanEvaluationScreenState();
}

class _PlanEvaluationScreenState extends State<PlanEvaluationScreen> {
  bool _isAppropriate = true;
  final _notesCtrl = TextEditingController();
  final _changesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _changesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final changes = _changesCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final ok = await ApiService.evaluatePlanAppropriateness(
        childId: widget.childId,
        planId: widget.planId,
        isAppropriate: _isAppropriate,
        notesForTeacher: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        recommendedChanges: changes.isEmpty ? null : changes,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.evaluationSaved),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.evaluationSaveFailed)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.evaluationSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.planEvaluationForChild(widget.childName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Material(
            color: c.tintTeal,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.planSuitabilityQuestion,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RadioGroup<bool>(
                  groupValue: _isAppropriate,
                  onChanged: (v) {
                    if (v != null) setState(() => _isAppropriate = v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<bool>(title: Text(context.l10n.planSuitable), value: true),
                      RadioListTile<bool>(title: Text(context.l10n.planNeedsChanges), value: false),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.l10n.notesForTeacher,
              alignLabelWithHint: true,
              hintText: context.l10n.notesForTeacherHint,
              prefixIcon: Icon(AppIcons.edit),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _changesCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: context.l10n.recommendedChanges,
              alignLabelWithHint: true,
              hintText: context.l10n.oneChangePerLine,
              prefixIcon: Icon(AppIcons.attach),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAppropriate ? AppColors.green : AppColors.orange,
              ),
              icon: Icon(_isAppropriate ? AppIcons.check : AppIcons.warning),
              label: Text(_saving ? context.l10n.saving : context.l10n.saveEvaluation),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
