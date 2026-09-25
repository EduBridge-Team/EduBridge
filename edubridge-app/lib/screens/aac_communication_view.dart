part of 'aac_communication_screen.dart';

extension AACCommunicationScreenStateView on _AACCommunicationScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final items = _categories[_selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: AdaptiveHelper.surfaceColor(context),
      appBar: JisrAppBar(title: 'تواصل بالصور'),
      body: Column(
        children: [
          // ─── الجملة الحالية ───
          Container(
            margin: EdgeInsets.all(AdaptiveHelper.spacing),
            padding: EdgeInsets.all(AdaptiveHelper.spacing),
            decoration: BoxDecoration(
              color: AdaptiveHelper.cardColor(context),
              borderRadius:
                  BorderRadius.circular(AdaptiveHelper.cardRadius),
              border: Border.all(
                color: AdaptiveHelper.accentColor(context),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  child: _sentence.isEmpty
                      ? Center(
                          child: Text(
                            'اضغط على الصور لبناء جملة',
                            style: TextStyle(
                              fontSize: AdaptiveHelper.bodyFontSize - 2,
                              color: c.muted,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sentence.map((word) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AdaptiveHelper.accentColor(context)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                word,
                                style: TextStyle(
                                  fontSize: AdaptiveHelper.bodyFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: AdaptiveHelper.accentColor(context),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                SizedBox(height: AdaptiveHelper.spacing),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, AdaptiveHelper.buttonHeight),
                        ),
                        onPressed: _speakAll,
                        icon: const Icon(AppIcons.volumeUp),
                        label: Text(
                          'قلها',
                          style:
                              TextStyle(fontSize: AdaptiveHelper.bodyFontSize),
                        ),
                      ),
                    ),
                    SizedBox(width: AdaptiveHelper.spacing / 2),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        minimumSize: Size(
                          AdaptiveHelper.buttonHeight,
                          AdaptiveHelper.buttonHeight,
                        ),
                      ),
                      onPressed: _removeLast,
                      icon: const Icon(Icons.backspace_outlined,
                          color: Colors.white),
                    ),
                    SizedBox(width: AdaptiveHelper.spacing / 2),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.red,
                        minimumSize: Size(
                          AdaptiveHelper.buttonHeight,
                          AdaptiveHelper.buttonHeight,
                        ),
                      ),
                      onPressed: _clear,
                      icon: const Icon(AppIcons.delete, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── التصنيفات ───
          SizedBox(
            height: AdaptiveHelper.buttonHeight * 0.9,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: AdaptiveHelper.spacing,
              ),
              children: _categories.keys.map((cat) {
                final selected = cat == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(
                      right: AdaptiveHelper.spacing / 2),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: AdaptiveHelper.bodyFontSize - 2,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : c.body,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AdaptiveHelper.accentColor(context),
                    onSelected: (v) {
                      if (v) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── شبكة الصور ───
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(AdaptiveHelper.spacing),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 4 : 2,
                mainAxisSpacing: AdaptiveHelper.spacing,
                crossAxisSpacing: AdaptiveHelper.spacing,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final (icon, label, spoken) = items[i];
                return _AACChip(
                  icon: icon,
                  label: label,
                  onTap: () => _addToSentence(label, spoken),
                );
              },
            ),
          ),
        ],
      ),
    );
  
  }
}
