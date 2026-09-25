// lib/screens/evaluation/evaluation_ministry_toggle.dart
part of 'evaluation_sheet.dart';

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
        color: active ? AppColors.orange.withValues(alpha: 0.08) : c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.orange : c.line,
          width: active ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.orange
                      : c.muted.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? AppColors.orangeDeep
                        : c.muted.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  active ? AppIcons.upload : AppIcons.attach,
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
                        color: active ? AppColors.orangeDeep : c.heading,
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
                activeThumbColor: AppColors.orange,
                inactiveThumbColor: c.muted,
                onChanged: onChanged,
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 14),
            _buildMinistryStepsBox(c),
          ] else ...[
            const SizedBox(height: 12),
            _buildFastTrackBox(c),
          ],
        ],
      ),
    ),
  );
}

Widget _buildMinistryStepsBox(JisrColors c) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: AppColors.orange.withValues(alpha: 0.2),
      ),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MinistryStep(
          icon: AppIcons.check,
          color: AppColors.green,
          text: 'عند الموافقة: يُشعَر المعلم والمختص',
        ),
        SizedBox(height: 8),
        _MinistryStep(
          icon: AppIcons.error,
          color: AppColors.red,
          text: 'عند الرفض: تعود إليك الخطة للتعديل',
        ),
        SizedBox(height: 8),
        _MinistryStep(
          icon: AppIcons.clock,
          color: AppColors.orange,
          text: 'قد يستغرق الرد من 24 إلى 48 ساعة',
        ),
      ],
    ),
  );
}

Widget _buildFastTrackBox(JisrColors c) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.brandTeal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: AppColors.brandTeal.withValues(alpha: 0.2),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.flash_on_outlined,
          color: AppColors.brandBlue,
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
            style: const TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}