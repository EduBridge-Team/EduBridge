import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';

/// Dashboard destination labels and visual selection, without route ownership.
class SpecialistBottomNavigation extends StatelessWidget {
  const SpecialistBottomNavigation({
    super.key,
    required this.tabIndex,
    required this.onSelected,
  });

  final int tabIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF8FA5B5), width: 1.5)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: c.card,
          indicatorColor: tabIndex == 1
              ? Colors.transparent
              : const Color(0xFFE1F0FF),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) && tabIndex == 0
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: states.contains(WidgetState.selected) && tabIndex == 0
                  ? const Color(0xFF1867BD)
                  : c.muted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected) && tabIndex == 0
                  ? const Color(0xFF1867BD)
                  : c.muted,
            ),
          ),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: 0,
          onDestinationSelected: onSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: context.l10n.children,
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              label: context.l10n.caseStudies,
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: context.l10n.conversations,
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              label: context.l10n.supportRequests,
            ),
          ],
        ),
      ),
    );
  }
}
