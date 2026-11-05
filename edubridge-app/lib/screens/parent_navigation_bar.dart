import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme.dart';

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
    final colors = JisrColors.of(context);
    const selectedColor = Color(0xFF1867BD);
    const labelSize = 12.0;
    final scaledLabelSize = MediaQuery.textScalerOf(context).scale(labelSize);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF8FA5B5), width: 1.5)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colors.card,
          indicatorColor: const Color(0xFFE1F0FF),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: labelSize,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? selectedColor : colors.muted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected)
                  ? selectedColor
                  : colors.muted,
            ),
          ),
        ),
        child: NavigationBar(
          height: scaledLabelSize > labelSize
              ? 76 + (scaledLabelSize - labelSize) * 2
              : 76,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.localeName.startsWith('ar') ? 'الرئيسية' : 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              label: l10n.parentLessons,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              label: l10n.conversations,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
