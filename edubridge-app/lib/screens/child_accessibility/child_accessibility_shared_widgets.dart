// lib/screens/child_accessibility/child_accessibility_shared_widgets.dart
part of 'child_accessibility_settings_screen.dart';

Widget buildInfoBanner(JisrColors c, String childName) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.tintTeal,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(AppIcons.child, color: AppColors.brandBlue, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'هذه الإعدادات تُطبَّق على $childName فقط.',
            style: TextStyle(color: c.onTint, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

Widget buildSectionTitle(String title, JisrColors c) {
  return Text(
    title,
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: c.heading,
    ),
  );
}

Widget buildDisabilitySelector({
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
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نوع الإعاقة',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasValue ? AppColors.brandBlue : c.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? selectedValue! : 'اضغط للاختيار',
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

Widget buildCustomDisabilityBox({
  required JisrColors c,
  required TextEditingController controller,
  required VoidCallback onSave,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.tintOrange,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.edit, color: AppColors.orangeDeep, size: 24),
            const SizedBox(width: 8),
            Text(
              'اكتب اسم الإعاقة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.onTint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'مثال: اضطراب المعالجة السمعية',
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(AppIcons.check),
            label: const Text('حفظ الإعاقة'),
            onPressed: onSave,
          ),
        ),
      ],
    ),
  );
}

Widget buildFeatureSection({
  required String title,
  required IconData icon,
  required Color color,
  required JisrColors c,
  required List<Widget> children,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: color.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

Widget sw(String t, String s, bool v, ValueChanged<bool> on) {
  return SwitchListTile(
    dense: true,
    title: Text(t,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
    subtitle: Text(s, style: const TextStyle(fontSize: 11.5)),
    value: v,
    onChanged: on,
  );
}