part of 'disability_picker_sheet.dart';

extension _DisabilityPickerS30 on _DisabilityPickerSheetState {
  Widget buildS30(BuildContext context) {
    final c = JisrColors.of(context);
    final categories = _filteredCategories;
    return Container(
      height: MediaQuery.sizeOf(context).height * .86,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [SliverToBoxAdapter(child: Column(children: [
          const SizedBox(height: 8),
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(4)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2684DD), size: 22),
              const SizedBox(width: 7),
              Flexible(child: Text(widget.title ?? context.l10n.selectDisability, textAlign: TextAlign.center,
                style: TextStyle(color: c.heading, fontSize: 19, fontWeight: FontWeight.w800))),
              IconButton(tooltip: context.l10n.close, onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF2684DD), size: 22)),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              key: const ValueKey('s30-search'),
              controller: _searchCtrl,
              onChanged: (value) => _refreshState(() => _search = value),
              decoration: InputDecoration(
                hintText: context.l10n.searchDisability,
                hintStyle: TextStyle(color: c.muted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: c.muted, size: 22),
                suffixIcon: _search.isEmpty ? null : IconButton(
                  tooltip: context.l10n.clearSearch, icon: const Icon(Icons.close_rounded, size: 19),
                  onPressed: () => _refreshState(() { _searchCtrl.clear(); _search = ''; })),
                filled: true, fillColor: c.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: c.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: c.line)),
              ),
            )),
        ])),
        if (categories.isEmpty && !_showOther && !_showNoAdaptation)
          SliverToBoxAdapter(child: _buildEmpty(c))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            sliver: SliverList.list(children: [
              for (final category in categories) _s30Category(c, category),
              if (_showOther) _s30Other(c),
              if (_showNoAdaptation) ...[
                const SizedBox(height: 10),
                _buildNoDisabilityOption(c),
              ],
            ]),
          ),
      ])),

    );
  }

  Widget _s30Badge(IconData icon) => Container(width: 46, height: 46,
    decoration: BoxDecoration(color: const Color(0xFFE0F6F8),
      borderRadius: BorderRadius.circular(16)),
    child: Icon(icon, color: const Color(0xFF10A9BA), size: 26));

  IconData _s30Icon(String label) => switch (label) {
    'الإعاقات البصرية' => Icons.visibility_outlined,
    'الإعاقات السمعية' => Icons.headphones_outlined,
    'اضطرابات النطق واللغة' => Icons.chat_bubble_outline_rounded,
    'الإعاقات الحركية والشلل' => Icons.people_outline_rounded,
    'إصابات وأمراض الدماغ' => Icons.lightbulb_outline_rounded,
    'الاضطرابات النمائية والسلوكية' => Icons.star_rounded,
    _ => Icons.menu_book_outlined,
  };

  Widget _s30Category(JisrColors c, DisabilityCategory category) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: c.card,
      elevation: 2, shadowColor: const Color(0x100F3658),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('s30-${category.label}-$_search'),
          initiallyExpanded: _search.trim().isNotEmpty || category.items.contains(widget.currentValue),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: _s30Badge(_s30Icon(category.label)),
          title: Text(DisabilityDisplay.label(category.label, context.l10n), style: TextStyle(color: c.heading,
            fontSize: 14, fontWeight: FontWeight.w800, height: 1.6)),
          subtitle: Text(context.l10n.disabilityCaseCount(category.items.length),
            style: TextStyle(color: c.muted, fontSize: 11)),
          iconColor: const Color(0xFF2684DD),
          collapsedIconColor: const Color(0xFF2684DD),
          children: [for (final item in category.items)
            ListTile(
              dense: true,
              title: Text(DisabilityDisplay.label(item, context.l10n), style: TextStyle(color: c.heading, fontSize: 14)),
              selected: widget.currentValue == item,
              trailing: widget.currentValue == item
                  ? const Icon(Icons.check_rounded, color: Color(0xFF1769C2)) : null,
              onTap: () => Navigator.pop(context, item),
            ),
          ],
        )),
    ),
  );

  Widget _s30Other(JisrColors c) => Material(
    color: c.card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.line)),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      key: const ValueKey('s30-other'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: _s30Badge(Icons.edit_outlined),
      title: Text(context.l10n.otherDisability, style: TextStyle(color: c.heading, fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(context.l10n.enterDisabilityYourself, style: TextStyle(color: c.muted, fontSize: 11)),
      trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2684DD)),
      onTap: () => Navigator.pop(context, 'أخرى'),
    ),
  );
}
