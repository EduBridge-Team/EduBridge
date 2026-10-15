// lib/screens/specialist/specialist_progress_tab.dart
part of 'specialist_screen.dart';

extension _ProgressTabExtension on _SpecialistDashboardScreenState {
  Widget buildProgressTab(BuildContext context, JisrColors c) {
    final displayChildren = _filteredChildren;

    if (displayChildren.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
        children: [
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
                  ? 'لا يوجد أطفال معيّنون لك حالياً'
                  : 'لا يوجد أطفال في قائمة الانتظار',
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
                  ? 'سيظهر الأطفال هنا عند إضافتهم إلى قائمة المتابعة.'
                  : 'ستظهر طلبات الأطفال هنا عند توفرها.',
              style: TextStyle(fontSize: 13, height: 1.6, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: displayChildren.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Row(
              children: [
                Text(
                  _showOnlyMine ? 'الأطفال تحت متابعتي' : 'قائمة الانتظار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${displayChildren.length}',
                    style: const TextStyle(
                      color: Color(0xFF1867BD),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final row = displayChildren[i - 1] as Map<String, dynamic>;
        return _showOnlyMine
            ? buildMyChildCard(row, c)
            : buildAvailableChildCard(row, c);
      },
    );
  }
}