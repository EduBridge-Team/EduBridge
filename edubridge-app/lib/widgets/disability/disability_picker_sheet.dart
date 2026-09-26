// lib/widgets/disability/disability_picker_sheet.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../theme.dart';
import 'disability_catalog.dart';
part 'disability_picker_sheet_view.dart';

class DisabilityPickerSheet extends StatefulWidget {
  final String? currentValue;
  final String title;

  const DisabilityPickerSheet({
    super.key,
    this.currentValue,
    this.title = 'اختر نوع الإعاقة',
  });

  @override
  State<DisabilityPickerSheet> createState() => _DisabilityPickerSheetState();
}

class _DisabilityPickerSheetState extends State<DisabilityPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DisabilityCategory> get _filteredCategories {
    if (_search.trim().isEmpty) return kDisabilityCategories;
    final q = _search.trim().toLowerCase();
    final result = <DisabilityCategory>[];
    for (final cat in kDisabilityCategories) {
      final matching = cat.items
          .where((item) => item.toLowerCase().contains(q))
          .toList();
      if (matching.isNotEmpty || cat.label.toLowerCase().contains(q)) {
        result.add(DisabilityCategory(
          label: cat.label,
          emoji: cat.emoji,
          items: matching.isEmpty ? cat.items : matching,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => buildView(context);

  Widget _buildHandle(JisrColors c) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: c.line,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(AppIcons.specialist, color: AppColors.brandBlue, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
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
    );
  }

  Widget _buildSearch(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'ابحث عن إعاقة...',
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(AppIcons.close),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
          filled: true,
          fillColor: c.tintTeal.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildEmpty(JisrColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.search, size: 64, color: c.muted),
            const SizedBox(height: 12),
            Text('لا توجد نتائج',
                style: TextStyle(fontSize: 16, color: c.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDisabilityOption(JisrColors c) {
    final isSelected = widget.currentValue == 'بدون تكييف';
    return _optionTile(
      c: c,
      selected: isSelected,
      onTap: () => Navigator.pop(context, 'بدون تكييف'),
      leading: const Icon(AppIcons.info, size: 22, color: AppColors.muted),
      title: 'بدون تكييف',
    );
  }

  Widget _buildOtherOption(JisrColors c) {
    final isSelected = widget.currentValue == 'أخرى';
    return InkWell(
      onTap: () => Navigator.pop(context, 'أخرى'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.2)
              : AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(AppIcons.edit,
                  size: 22, color: AppColors.orangeDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أخرى',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                  Text('اكتب نوع الإعاقة بنفسك',
                      style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            const Icon(AppIcons.back, color: AppColors.orange),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required JisrColors c,
    required bool selected,
    required VoidCallback onTap,
    required Widget leading,
    required String title,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandBlue.withValues(alpha: 0.15)
              : c.tintTeal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandBlue : c.line,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  )),
            ),
            if (selected)
              const Icon(AppIcons.check, color: AppColors.brandBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(DisabilityCategory cat, JisrColors c) {
    final hasCurrent =
        widget.currentValue != null && cat.items.contains(widget.currentValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: ExpansionTile(
        initiallyExpanded: hasCurrent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
        iconColor: AppColors.brandBlue,
        collapsedIconColor: c.muted,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(cat.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: c.heading,
            )),
        subtitle: Text(
          '${cat.items.length} ${cat.items.length == 1 ? 'حالة' : 'حالات'}',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        children: cat.items.map((item) {
          final isSelected = widget.currentValue == item;
          return InkWell(
            onTap: () => Navigator.pop(context, item),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandBlue.withValues(alpha: 0.2)
                    : c.tintTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: AppColors.brandBlue, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? AppIcons.check : AppIcons.back,
                    size: 18,
                    color: AppColors.brandBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: c.heading,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}