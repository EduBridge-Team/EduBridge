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
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: c.line),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '؟',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        need.isEmpty ? 'طالب قيد المتابعة' : need,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.starFilled,
                            size: 14,
                            color: AppColors.brandTealLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stats['pct']}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 5),
                      Text(
                        'بانتظار التقييم',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: c.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (child['has_pending_therapy_request'] == true) ...[
              const SizedBox(height: 12),
              _buildPendingSupportBanner(),
            ],
            if (current != null ||
                (stats['inProgress'] as int) > 0 ||
                (stats['done'] as int) > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (current != null)
                    _CountBadge(
                      '${current['lesson_title'] ?? 'نشاط حالي'}',
                      color: AppColors.brandTealDeep,
                    ),
                  if ((stats['inProgress'] as int) > 0)
                    _CountBadge(
                      '${stats['inProgress']} قيد التنفيذ',
                      color: AppColors.brandBlue,
                    ),
                  if ((stats['done'] as int) > 0)
                    _CountBadge(
                      '${stats['done']} مكتمل',
                      color: AppColors.lightTeal,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openChildProfile(child),
                      icon: const Icon(Icons.folder_open_outlined, size: 19),
                      label: const Text(
                        'فتح ملف الطالب',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        isPending ? AppIcons.evaluate : AppIcons.view,
                        size: 18,
                      ),
                      label: Text(
                        isPending ? 'تقييم' : 'التقييم',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: isPending
                          ? () => _openEvaluation(row)
                          : () => _viewEvaluation(childId),
                    ),
                  ),
                ),
              ],
            ),
            if (!isPending) ...[
              const SizedBox(height: 10),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  maintainState: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  childrenPadding: const EdgeInsets.only(top: 6, bottom: 2),
                  leading: const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.brandBlue,
                  ),
                  title: Text(
                    'إجراءات سريعة',
                    style: TextStyle(
                      color: c.heading,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            ),
                            icon: const Icon(AppIcons.report, size: 17),
                            label: const Text('تقرير المعلم'),
                            onPressed: () => _openTeacherReport(row),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            ),
                            icon: const Icon(AppIcons.edit, size: 17),
                            label: const Text('اكتب تقدّم'),
                            onPressed: () => _writeProgressBasedOnReport(row),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            ),
                            icon: const Icon(AppIcons.forum, size: 17),
                            label: const Text('دراسة الحالة'),
                            onPressed: () => _openCaseDiscussion(childId: childId),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            ),
                            icon: const Icon(AppIcons.specialist, size: 17),
                            label: const Text('اقترح دعم'),
                            onPressed: () => _recommendLearningSupport(row),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _buildSuggestSpecialistButtons(row, child),
                    if (child['current_plan_id'] != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          icon: const Icon(AppIcons.evaluate),
                          label: const Text('تقييم الخطة الحالية'),
                          onPressed: () => _openPlanEvaluation(row),
                        ),
                      ),
                    ],
                    if (current != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          icon: approving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(AppIcons.check),
                          label: Text(approving ? 'جارٍ الاعتماد...' : 'اعتماد النشاط الحالي'),
                          onPressed: approving ? null : () => _approve(row),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
