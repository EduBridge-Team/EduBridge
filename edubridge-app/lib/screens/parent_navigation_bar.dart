import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class ParentNavigationBar extends StatelessWidget {
  const ParentNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final destinations = [
      (Icons.home_outlined, l10n.localeName.startsWith('ar') ? 'الرئيسية' : 'Home'),
      (Icons.menu_book_outlined, l10n.parentLessons),
      (Icons.chat_bubble_outline, l10n.conversations),
      (Icons.person_outline, l10n.profile),
    ];
    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final (index, (icon, label)) in destinations.indexed)
              Expanded(
                child: Semantics(
                  selected: index == selectedIndex,
                  child: TextButton(
                    onPressed: () => onSelected(index),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      foregroundColor: index == selectedIndex
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon),
                        const SizedBox(height: 4),
                        Text(label, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
