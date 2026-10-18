// lib/screens/child_accessibility/child_accessibility_shared_widgets.dart
part of 'child_accessibility_settings_screen.dart';

PreferredSizeWidget buildChildSettingsAppBar(BuildContext context, String childName) => BrandAppBar(
  toolbarHeight: 96,
  centerTitle: false,
  titleSpacing: 0,
  leadingWidth: 52,
  leading: IconButton(
    tooltip: 'رجوع', onPressed: () => Navigator.maybePop(context),
    icon: const CircleAvatar(radius: 19, backgroundColor: Color(0x33FFFFFF),
      child: Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white))),
  title: Text('إعدادات $childName', maxLines: 1, overflow: TextOverflow.ellipsis,
    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
);

Widget _settingsBadge(IconData icon) => Container(
  width: 36, height: 36,
  decoration: BoxDecoration(color: const Color(0xFFE2F5F7),
    borderRadius: BorderRadius.circular(11)),
  child: Icon(icon, color: const Color(0xFF09ACC0), size: 20),
);

Widget buildInfoBanner(JisrColors c, String childName) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
  child: Row(children: [
    _settingsBadge(Icons.people_outline_rounded),
    const SizedBox(width: 12),
    Expanded(child: Text('هذه الإعدادات تُطبَّق على $childName فقط.',
      style: TextStyle(color: c.heading, fontSize: 15, height: 1.7, fontWeight: FontWeight.w700))),
  ]),
);

Widget buildDisabilitySelector({
  required JisrColors c,
  required String? selectedValue,
  required VoidCallback? onTap,
}) => Material(
  color: c.card,
  borderRadius: BorderRadius.circular(18),
  clipBehavior: Clip.antiAlias,
  child: InkWell(onTap: onTap, child: Padding(
    padding: const EdgeInsets.all(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: c.tintTeal.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _settingsBadge(Icons.description_outlined),
        const SizedBox(width: 8),
        Expanded(child: Text(selectedValue == null ? 'نوع الإعاقة' : 'نوع الإعاقة: $selectedValue',
          style: TextStyle(color: c.muted, fontSize: 13))),
        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1769C2), size: 21),
      ]),
    ),
  )),
);

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
            const Icon(AppIcons.edit, color: AppColors.brandTealDeep, size: 24),
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
              backgroundColor: AppColors.brandTealDeep,
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
  bool initiallyExpanded = true,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Material(
    color: c.card,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: Builder(builder: (context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('s27-$title'),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: _settingsBadge(Icons.people_outline_rounded),
          title: Text(title, style: TextStyle(color: c.heading,
            fontSize: 15, fontWeight: FontWeight.w800, height: 1.6)),
          iconColor: const Color(0xFF1769C2),
          collapsedIconColor: const Color(0xFF1769C2),
          children: children,
        ),
      )),
  ),
);

Widget sw(String t, String s, bool v, ValueChanged<bool> on, {bool enabled = true}) => Builder(
  builder: (context) {
    final c = JisrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? c.tintTeal : const Color(0xFFEEF6FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Tooltip(
          message: s,
          child: SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 4),
            visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
            title: Text(t, style: TextStyle(color: c.heading, fontSize: 13)),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF10BFD0),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCCD9EA),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            value: v,
            onChanged: enabled ? on : null,
          ),
        ),
      ),
    );
  },
);

Widget buildDurationSetting({
  required String title,
  required String subtitle,
  required int value,
  required List<int> choices,
  required String unit,
  required ValueChanged<int>? onChanged,
}) {
  final options = {...choices, value}.toList()..sort();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12)),
        Semantics(
          label: title,
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            items: options.map((option) => DropdownMenuItem(
              value: option, child: Text('$option $unit'),
            )).toList(),
            onChanged: onChanged == null ? null : (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ],
    ),
  );
}
