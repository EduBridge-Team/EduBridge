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
        color: AppColors.brandTealDeep.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandTealDeep, width: 2),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.specialist,
              color: AppColors.brandTealDeep, size: 28),
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

  Widget _buildAdaptationAndSpecialistActions(
    Map<String, dynamic> row,
    Map<String, dynamic> child,
  ) {
    final needsSupport = !_hasSpecialistOfType(child, 'learning_support');
    final needsEducational = !_hasSpecialistOfType(child, 'educational');
    final suggestionType = needsSupport ? 'learning_support' : 'educational';
    final showSuggestion = needsSupport || needsEducational;
    final style = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    );

    return Row(children: [
      Expanded(child: OutlinedButton.icon(
        style: style,
        icon: const Icon(Icons.accessibility_new_rounded, size: 17),
        label: const Text('تكييف التعلّم'),
        onPressed: () => _openChildAdaptation(child),
      )),
      const SizedBox(width: 10),
      Expanded(child: showSuggestion ? OutlinedButton.icon(
        style: style,
        icon: Icon(needsSupport ? AppIcons.specialist : AppIcons.lesson, size: 17),
        label: Text(needsSupport ? 'اقترح مختص دعم تعليمي' : 'اقترح مختص تعليمي',
            textAlign: TextAlign.center),
        onPressed: () => _openSuggestSpecialist(row, suggestionType),
      ) : const SizedBox.shrink()),
    ]);
  }

}

// ═══════════════════════════════════════════════════════════
//  Helpers عامة (top-level functions)
// ═══════════════════════════════════════════════════════════
