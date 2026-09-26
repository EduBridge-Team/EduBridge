// lib/screens/add_child/add_child_disability_field.dart
part of 'add_child_screen.dart';

Widget buildDisabilityField({
  required BuildContext context,
  required JisrColors c,
  required String? selectedValue,
  required VoidCallback onTap,
}) {
  final hasValue = selectedValue != null;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue ? AppColors.brandBlue : c.line,
          width: hasValue ? 2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.specialist,
            color: hasValue ? AppColors.brandBlue : c.muted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نوع الإعاقة *',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasValue ? AppColors.brandBlue : c.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? selectedValue : 'اضغط للاختيار',
                  style: TextStyle(
                    fontSize: 15,
                    color: hasValue ? c.heading : c.muted,
                    fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: hasValue ? AppColors.brandBlue : c.muted,
          ),
        ],
      ),
    ),
  );
}