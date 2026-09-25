// lib/screens/educational_plan_sheet.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';

class EducationalPlanSheet extends StatefulWidget {
  final Map child;

  const EducationalPlanSheet({super.key, required this.child});

  @override
  State<EducationalPlanSheet> createState() => _EducationalPlanSheetState();
}

class _EducationalPlanSheetState extends State<EducationalPlanSheet> {
  Map? _evaluation;
  bool _loading = true;
  String? _error;

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
      if (evaluations.isNotEmpty) {
        setState(() {
          _evaluation = evaluations.last;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'لا يوجد تقييم مسجل لهذا الطفل';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل التقييم';
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
                        Text(_error!, style: TextStyle(color: c.muted)),
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
                              'الخطة التعليمية - ${widget.child['name'] ?? ''}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: c.heading,
                              ),
                            ),
                          ),
                          IconButton(
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
                                const Text(
                                  'ملخص التقييم',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_evaluation?['recommendations'] != null)
                              Text('التوصيات: ${_evaluation?['recommendations']}'),
                            if (_evaluation?['educational_plan'] != null) ...[
                              const SizedBox(height: 8),
                              Text('الخطة: ${_evaluation?['educational_plan']}'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'التقييمات التفصيلية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _detailRow(AppIcons.cognitive, 'المعرفي',
                          _evaluation?['cognitive_assessment']),
                      _detailRow(AppIcons.motor, 'الحركي',
                          _evaluation?['motor_assessment']),
                      _detailRow(AppIcons.speech, 'العاطفي',
                          _evaluation?['emotional_assessment']),
                      _detailRow(AppIcons.users, 'الاجتماعي',
                          _evaluation?['social_assessment']),

                      const SizedBox(height: 16),

                      if (_evaluation?['teaching_methods'] != null) ...[
                        const Text(
                          'طرق التدريس المقترحة',
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
                          child: const Text('إغلاق'),
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