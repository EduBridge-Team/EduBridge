// lib/screens/specialist/specialist_progress_tab.dart
part of 'specialist_screen.dart';

extension _ProgressTabExtension on _SpecialistDashboardScreenState {
  Widget buildProgressTab(BuildContext context, JisrColors c) {
    final displayChildren = _filteredChildren;

    if (displayChildren.isEmpty) {
      if (!_showOnlyMine) {
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          sliver: SliverToBoxAdapter(
            child: SpecialistWaitingEmptyS29(isSearch: _searchQuery.isNotEmpty),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
        sliver: SliverList.list(children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F6FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showOnlyMine ? Icons.person_off_outlined : AppIcons.clock,
                size: 46,
                color: const Color(0xFF168CC5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _showOnlyMine
                  ? context.l10n.noAssignedChildren
                  : context.l10n.noWaitingChildren,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.heading,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _showOnlyMine
                  ? context.l10n.followUpChildrenDescription
                  : context.l10n.waitingChildrenDescription,
              style: TextStyle(fontSize: 13, height: 1.6, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      sliver: SliverList.builder(
      itemCount: displayChildren.length,
      itemBuilder: (context, i) {
        final row = displayChildren[i] as Map<String, dynamic>;
        return _showOnlyMine
            ? buildMyChildCard(row, c)
            : buildAvailableChildCard(row, c);
      },
      ),
    );
  }
}
