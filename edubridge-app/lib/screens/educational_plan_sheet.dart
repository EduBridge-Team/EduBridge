// lib/screens/educational_plan_sheet.dart
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';

enum _PlanError { empty, load }

class EducationalPlanSheet extends StatefulWidget {
  final Map child;

  const EducationalPlanSheet({super.key, required this.child});

  @override
  State<EducationalPlanSheet> createState() => _EducationalPlanSheetState();
}

class _EducationalPlanSheetState extends State<EducationalPlanSheet> {
  Map? _evaluation;
  bool _loading = true;
  _PlanError? _error;

  @override
  void initState() {
    super.initState();
    _loadEvaluation();
  }

  Future<void> _loadEvaluation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final evaluations = await ApiService.getChildEvaluations(widget.child['id']);
      if (!mounted) return;
      if (evaluations.isNotEmpty) {
        setState(() {
          // The existing API returns newest evaluations first.
          _evaluation = evaluations.first;
          _loading = false;
        });
      } else {
        setState(() {
          _error = _PlanError.empty;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _PlanError.load;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      children: [
                        Icon(AppIcons.error, size: 48, color: c.muted),
                        const SizedBox(height: 12),
                        Text(_error == _PlanError.empty
                            ? context.l10n.planEvaluationMissing
                            : context.l10n.planEvaluationFailed, style: TextStyle(color: c.muted)),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(AppIcons.plan,
                              color: AppColors.brandBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.planChildTitle((widget.child['name'] ?? '').toString()),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: c.heading,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: context.l10n.close,
                            icon: const Icon(AppIcons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.tintTeal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(AppIcons.info,
                                    color: AppColors.brandBlue, size: 20),
                                const SizedBox(width: 6),
                                Expanded(child: Text(
                                  context.l10n.planEvaluationSummary,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_evaluation?['recommendations'] != null)
                              Text(context.l10n.planRecommendationsValue(_evaluation!['recommendations'].toString())),
                            if (_evaluation?['educational_plan'] != null) ...[
                              const SizedBox(height: 8),
                              Text(context.l10n.planContentValue(_evaluation!['educational_plan'].toString())),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        context.l10n.planDetailedEvaluations,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _detailRow(AppIcons.cognitive, context.l10n.planCognitive,
                          _evaluation?['cognitive_assessment']),
                      _detailRow(AppIcons.motor, context.l10n.planMotor,
                          _evaluation?['motor_assessment']),
                      _detailRow(AppIcons.speech, context.l10n.planEmotional,
                          _evaluation?['emotional_assessment']),
                      _detailRow(AppIcons.users, context.l10n.planSocial,
                          _evaluation?['social_assessment']),

                      const SizedBox(height: 16),

                      if (_evaluation?['teaching_methods'] != null) ...[
                        Text(
                          context.l10n.suggestedTeachingMethods,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_evaluation?['teaching_methods'] as List? ?? [])
                              .map((method) => Chip(
                                    label: Text(method),
                                    backgroundColor: c.tintGreen,
                                  ))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.l10n.close),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final c = JisrColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brandBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: c.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}