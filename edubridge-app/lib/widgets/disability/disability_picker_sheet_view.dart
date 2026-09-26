part of 'disability_picker_sheet.dart';

extension _DisabilityPickerSheetStateView on _DisabilityPickerSheetState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final categories = _filteredCategories;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(c),
          _buildHeader(c),
          _buildSearch(c),
          Flexible(
            child: categories.isEmpty
                ? _buildEmpty(c)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      _buildNoDisabilityOption(c),
                      const SizedBox(height: 8),
                      ...categories.map((cat) => _buildCategory(cat, c)),
                      const SizedBox(height: 8),
                      _buildOtherOption(c),
                    ],
                  ),
          ),
        ],
      ),
    );
  
  }
}
