part of 'disability_picker_sheet.dart';

extension _DisabilityPickerSheetStateView on _DisabilityPickerSheetState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final categories = _filteredCategories;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: CustomScrollView(
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: Column(children: [
            _buildHandle(c),
            _buildHeader(c),
            _buildSearch(c),
          ])),
          if (categories.isEmpty && !_showOther && !_showNoAdaptation)
            SliverToBoxAdapter(child: _buildEmpty(c))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList.list(children: [
                if (_showNoAdaptation) ...[
                  _buildNoDisabilityOption(c),
                  const SizedBox(height: 8),
                ],
                ...categories.map((cat) => _buildCategory(cat, c)),
                if (_showOther) ...[
                  const SizedBox(height: 8),
                  _buildOtherOption(c),
                ],
              ]),
            ),
        ],
      ),
    );
  }
}
