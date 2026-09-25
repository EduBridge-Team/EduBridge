// lib/screens/specialist/specialist_child_cards.dart
part of 'specialist_screen.dart';

extension _ChildCardsExtension on _SpecialistDashboardScreenState {
  // ═══════════════════════════════════════════════════════════
  //  بطاقة الطفل "المتاح" (قائمة الانتظار)
  // ═══════════════════════════════════════════════════════════
  Widget _buildPendingSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple, width: 2),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.specialist,
              color: AppColors.purple, size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('طلب دعم تعليمي',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.purple,
                    )),
                Text('ولي الأمر يطلب اجتماع دعم تعليمي',
                    style: TextStyle(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const LearningSupportRequestsScreen(),
              ),
            ),
            child: const Text('اعرض',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Helper: أزرار اقتراح مختص ───
  Widget _buildSuggestSpecialistButtons(
    Map<String, dynamic> row,
    Map<String, dynamic> child,
  ) {
    final hasLearningSupport =
        _hasSpecialistOfType(child, 'learning_support');
    final hasEducational = _hasSpecialistOfType(child, 'educational');

    if (hasLearningSupport && hasEducational) {
      return const SizedBox.shrink();
    }

    if (!hasLearningSupport) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColors.purple,
              side: const BorderSide(
                  color: AppColors.purple, width: 1.5),
            ),
            icon: const Icon(AppIcons.specialist, size: 18),
            label: const Text(
              'اقترح مختص دعم تعليمي',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () =>
                _openSuggestSpecialist(row, 'learning_support'),
          ),
        ),
      );
    }

    if (!hasEducational) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(
                  color: AppColors.brandBlue, width: 1.5),
            ),
            icon: const Icon(AppIcons.lesson, size: 18),
            label: const Text(
              'اقترح مختص تعليمي',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () =>
                _openSuggestSpecialist(row, 'educational'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                foregroundColor: AppColors.purple,
                side: const BorderSide(
                    color: AppColors.purple, width: 1.5),
              ),
              icon: const Icon(AppIcons.specialist, size: 16),
              label: const Text('اقترح مختص دعم تعليمي',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold)),
              onPressed: () =>
                  _openSuggestSpecialist(row, 'learning_support'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                foregroundColor: AppColors.brandBlue,
                side: const BorderSide(
                    color: AppColors.brandBlue, width: 1.5),
              ),
              icon: const Icon(AppIcons.lesson, size: 16),
              label: const Text('اقترح مختص تعليمي',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold)),
              onPressed: () =>
                  _openSuggestSpecialist(row, 'educational'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Helpers عامة (top-level functions)
// ═══════════════════════════════════════════════════════════
Widget _infoRowExt(String label, String value, JisrColors c) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: c.muted,
              )),
        ),
        Expanded(
          child: Text(value,
              style:
                  TextStyle(fontSize: 13, color: c.body, height: 1.4)),
        ),
      ],
    ),
  );
}

Widget _chipsRowExt(String label, List<String> items, JisrColors c,
    Color color, Color bg) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: c.muted,
              )),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s,
                          style:
                              TextStyle(fontSize: 11, color: color)),
                    ))
                .toList(),
          ),
        ),
      ],
    ),
  );
}
