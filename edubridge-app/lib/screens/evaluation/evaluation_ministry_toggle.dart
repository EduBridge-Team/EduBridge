// lib/screens/evaluation/evaluation_ministry_toggle.dart
part of 'evaluation_sheet.dart';

// ═══════════════════════════════════════════════════════════
//  بطاقة "إرسال للوزارة"
// ═══════════════════════════════════════════════════════════
Widget buildMinistryToggleCard({
  required JisrColors c,
  required bool active,
  required ValueChanged<bool> onChanged,
}) {
  return InkWell(
    onTap: () => onChanged(!active),
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? AppColors.brandBlueLight.withValues(alpha: 0.08) : c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.brandBlueLight : c.line,
          width: active ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ─── أيقونة دائرية ───
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.blue
                      : c.muted.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? AppColors.brandBlueDeep
                        : c.muted.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  active ? Icons.how_to_reg : Icons.upload_file,
                  color: active ? Colors.white : c.muted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إرسال الخطة للوزارة للموافقة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: active ? AppColors.brandBlueDeep : c.heading,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active
                          ? 'سيتم مراجعة الخطة من الوزارة'
                          : 'لن تُرسل للوزارة — تُرسل للمعلم مباشرة',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                activeThumbColor: AppColors.brandBlueLight,
                inactiveThumbColor: c.muted,
                onChanged: onChanged,
              ),
            ],
          ),

          // ─── تفاصيل عند التفعيل ───
          if (active) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MinistryStep(
                    icon: Icons.check_circle,
                    color: AppColors.brandTealDeep,
                    text: 'عند الموافقة: يُشعَر المعلم والمختص',
                  ),
                  SizedBox(height: 8),
                  _MinistryStep(
                    icon: Icons.cancel,
                    color: AppColors.brandBlueDeep,
                    text: 'عند الرفض: تعود إليك الخطة للتعديل',
                  ),
                  SizedBox(height: 8),
                  _MinistryStep(
                    icon: Icons.schedule,
                    color: AppColors.brandGreen,
                    text: 'قد يستغرق الرد من 24 إلى 48 ساعة',
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.flash_on,
                    color: AppColors.tealDeep,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المسار السريع',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: c.onTint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'التقييم يُرسل مباشرة للمعلم لبدء التنفيذ بدون انتظار، ويُشعَر المعلم فوراً.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.onTint,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MinistryStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MinistryStep({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}