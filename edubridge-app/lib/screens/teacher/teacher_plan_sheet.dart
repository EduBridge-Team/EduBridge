// lib/screens/teacher/teacher_plan_sheet.dart
part of 'teacher_screen.dart';

class _ApprovedPlanSheet extends StatelessWidget {
  final Map plan;

  const _ApprovedPlanSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 60, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
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
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
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
                borderRadius: BorderRadius.circular(16),
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
            _planSection(
              AppIcons.lesson,
              'الخطة التعليمية',
              plan['educational_plan'],
              c,
            ),
            _planSection(
              Icons.psychology_outlined,
              'التقييم المعرفي',
              plan['cognitive_assessment'],
              c,
            ),
            _planSection(
              Icons.directions_walk_outlined,
              'التقييم الحركي',
              plan['motor_assessment'],
              c,
            ),
            _planSection(
              Icons.favorite_border_rounded,
              'التقييم العاطفي',
              plan['emotional_assessment'],
              c,
            ),
            _planSection(
              AppIcons.users,
              'التقييم الاجتماعي',
              plan['social_assessment'],
              c,
            ),
            _planSection(
              Icons.lightbulb_outline_rounded,
              'التوصيات',
              plan['recommendations'],
              c,
            ),
            if (plan['teaching_methods'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'طرق التدريس المقترحة',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: c.heading,
                ),
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

  Widget _planSection(
    IconData icon,
    String label,
    dynamic value,
    JisrColors c,
  ) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.tintTeal.withValues(alpha: .32),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.brandBlue),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: c.heading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 14, height: 1.55, color: c.body),
            ),
          ],
        ),
      ),
    );
  }
}