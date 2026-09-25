// lib/screens/specialist/specialist_progress_tab.dart
part of 'specialist_screen.dart';

extension _ProgressTabExtension on _SpecialistDashboardScreenState {
  Widget buildProgressTab(BuildContext context, JisrColors c) {
    final displayChildren = _filteredChildren;

    if (displayChildren.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(
            _showOnlyMine ? Icons.person_off_outlined : AppIcons.clock,
            size: 72,
            color: c.muted,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _showOnlyMine
                  ? 'لا يوجد أطفال معيّنون لك حالياً'
                  : 'لا يوجد أطفال في قائمة الانتظار',
              style: TextStyle(fontSize: 18, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: displayChildren.length,
      itemBuilder: (context, i) {
        final row = displayChildren[i] as Map<String, dynamic>;
        return _showOnlyMine
            ? buildMyChildCard(row, c)
            : buildAvailableChildCard(row, c);
      },
    );
  }
}