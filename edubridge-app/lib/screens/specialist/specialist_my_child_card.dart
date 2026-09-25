// Assigned-child card extracted from specialist_child_cards.dart.
part of 'specialist_screen.dart';

extension _MyChildCardExtension on _SpecialistDashboardScreenState {
  Widget buildMyChildCard(Map<String, dynamic> row, JisrColors c) {
    final child = row['child'] as Map<String, dynamic>;
    final stats = row['stats'] as Map<String, dynamic>;
    final current = stats['current'];
    final name = (child['name'] ?? '').toString();
    final need = (child['disability_type'] ?? '').toString();
    final childId = child['id'];
    final approving = _approvingId == childId;
    final status = child['status'] ?? 'pending';
    final isPending = status == 'pending' || status == '';
    final color = AppColors
        .kidPalette[_rows.indexOf(row) % AppColors.kidPalette.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── الرأس ───
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '؟',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await AccessibilityService.instance.setActiveChild(
                        childId,
                        disabilityTypeHint:
                            child['disability_type']?.toString(),
                      );
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => ChildProgressScreen(
                            childId: childId,
                            childName: name,
                          ),
                        ),
                      );
                      await AccessibilityService.instance
                          .setActiveChild(null);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.heading,
                            )),
                        if (need.isNotEmpty)
                          Text('الإعاقة: $need',
                              style: TextStyle(
                                  fontSize: 13, color: c.muted)),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.starFilled,
                            size: 16, color: AppColors.yellow),
                        const SizedBox(width: 4),
                        Text('${stats['pct']}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandBlue,
                            )),
                      ],
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('بانتظار التقييم',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orangeDeep,
                            )),
                      ),
                  ],
                ),
              ],
            ),

            // ─── شارة طلب دعم ───
            if (child['has_pending_therapy_request'] == true) ...[
              const SizedBox(height: 10),
              _buildPendingSupportBanner(),
            ],

            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (current != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.tintOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.clock,
                            size: 12, color: AppColors.orangeDeep),
                        const SizedBox(width: 4),
                        Text(
                          '${current['lesson_title'] ?? ''}',
                          style:
                              TextStyle(fontSize: 13, color: c.onTint),
                        ),
                      ],
                    ),
                  ),
                if ((stats['inProgress'] as int) > 0)
                  _CountBadge('${stats['inProgress']} قيد التنفيذ',
                      color: AppColors.brandBlue),
                if ((stats['done'] as int) > 0)
                  _CountBadge('${stats['done']} مكتمل',
                      color: AppColors.lightTeal),
              ],
            ),

            const SizedBox(height: 12),

            // ─── تقييم / عرض + اعتماد ───
            Row(
              children: [
                Expanded(
                  child: isPending
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                          ),
                          icon: const Icon(AppIcons.evaluate,
                              color: Colors.white),
                          label: const Text('تقييم الطفل'),
                          onPressed: () => _openEvaluation(row),
                        )
                      : OutlinedButton.icon(
                          icon: const Icon(AppIcons.view),
                          label: const Text('عرض التقييم'),
                          onPressed: () => _viewEvaluation(childId),
                        ),
                ),
                if (!isPending && current != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightTeal,
                      ),
                      icon: approving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(AppIcons.check,
                              color: Colors.white),
                      label: Text(
                        approving ? 'جارٍ...' : 'اعتماد',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onPressed: approving ? null : () => _approve(row),
                    ),
                  ),
                ],
              ],
            ),

            // ─── تقرير المعلم / اكتب تقدّم ───
            if (!isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.brandBlue,
                        side: const BorderSide(
                            color: AppColors.brandBlue, width: 1.5),
                      ),
                      icon: const Icon(AppIcons.report, size: 18),
                      label: const Text('تقرير المعلم',
                          style: TextStyle(fontSize: 13)),
                      onPressed: () => _openTeacherReport(row),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: AppColors.lightTeal,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(AppIcons.edit, size: 18),
                      label: const Text('اكتب تقدّم',
                          style: TextStyle(fontSize: 13)),
                      onPressed: () => _writeProgressBasedOnReport(row),
                    ),
                  ),
                ],
              ),

              // ─── دراسة الحالة / اقترح دعم ───
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.brandTeal,
                        side: const BorderSide(
                            color: AppColors.brandTeal, width: 1.5),
                      ),
                      icon: const Icon(AppIcons.forum, size: 18),
                      label: const Text('دراسة الحالة',
                          style: TextStyle(fontSize: 13)),
                      onPressed: () =>
                          _openCaseDiscussion(childId: childId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(AppIcons.specialist, size: 18),
                      label: const Text('اقترح دعم',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _recommendLearningSupport(row),
                    ),
                  ),
                ],
              ),

              // ─── اقتراح مختص دعم/تعليمي ───
              _buildSuggestSpecialistButtons(row, child),
            ],

            // ─── تقييم الخطة ───
            if (!isPending && child['current_plan_id'] != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lightTeal,
                    side:
                        const BorderSide(color: AppColors.lightTeal),
                  ),
                  icon: const Icon(AppIcons.evaluate),
                  label: const Text('تقييم الخطة الحالية'),
                  onPressed: () => _openPlanEvaluation(row),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Helper: شارة طلب دعم ───
}
