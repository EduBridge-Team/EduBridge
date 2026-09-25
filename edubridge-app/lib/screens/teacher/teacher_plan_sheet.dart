// lib/screens/teacher/teacher_plan_sheet.dart
part of 'teacher_screen.dart';

class _ApprovedPlanSheet extends StatelessWidget {
  final Map plan;

  const _ApprovedPlanSheet({required this.plan});

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.verified, color: AppColors.green, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الخطة المعتمدة - ${plan['child_name'] ?? ''}',
                    style: TextStyle(
                      fontSize: 18,
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.check, color: AppColors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم اعتماد هذه الخطة من الوزارة',
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _planSection('الخطة التعليمية', plan['educational_plan'], c),
            _planSection('التقييم المعرفي', plan['cognitive_assessment'], c),
            _planSection('التقييم الحركي', plan['motor_assessment'], c),
            _planSection('التقييم العاطفي', plan['emotional_assessment'], c),
            _planSection('التقييم الاجتماعي', plan['social_assessment'], c),
            _planSection('التوصيات', plan['recommendations'], c),
            if (plan['teaching_methods'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'طرق التدريس المقترحة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (plan['teaching_methods'] as List? ?? [])
                    .map((m) => Chip(
                          label: Text(m.toString()),
                          backgroundColor: c.tintGreen,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _planSection(String label, dynamic value, JisrColors c) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value.toString(),
              style: TextStyle(fontSize: 14, height: 1.5, color: c.body)),
        ],
      ),
    );
  }
}