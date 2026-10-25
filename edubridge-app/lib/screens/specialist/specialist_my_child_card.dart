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
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: c.line),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD7EAF8),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          PresentationText.initial(name, fallback: '؟'),
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.line),
                          ),
                          child: Text(
                            "${stats['pct']}%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: c.infoText,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        need.isEmpty ? context.l10n.followUpActive : need,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.muted),
                      ),
                    ],
                  ),
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
                      (current['lesson_title'] ?? context.l10n.currentActivity).toString(),
                      color: AppColors.brandTealDeep,
                    ),
                  if ((stats['inProgress'] as int) > 0)
                    _CountBadge(
                      context.l10n.inProgressActivityCount(stats['inProgress'] ?? 0),
                      color: AppColors.brandBlue,
                    ),
                  if ((stats['done'] as int) > 0)
                    _CountBadge(
                      context.l10n.completedActivityCount(stats['done'] ?? 0),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _openChildProfile(child),
                      icon: const Icon(Icons.folder_open_outlined, size: 19),
                      label: Text(
                        context.l10n.openChildProfile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
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
                        foregroundColor: c.infoText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        isPending ? AppIcons.evaluate : AppIcons.view,
                        size: 18,
                      ),
                      label: Text(
                        isPending ? context.l10n.evaluate : context.l10n.evaluation,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: isPending
                          ? () => _openEvaluation(row)
                          : () => _viewEvaluation(childId, childName: name),
                    ),
                  ),
                ),
              ],
            ),
            if (!isPending) ...[
              const SizedBox(height: 14),
              Divider(height: 1, thickness: 1, color: c.line),
              const SizedBox(height: 4),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  maintainState: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 6),
                  leading: Icon(
                    Icons.tune_outlined,
                    size: 20,
                    color: c.infoText,
                  ),
                  title: Text(
                    context.l10n.quickActions,
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
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              foregroundColor: const Color(0xFF176CCB),
                              side: BorderSide(color: c.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.bar_chart_outlined, size: 18),
                            label: Text(context.l10n.teacherReport, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onPressed: () => _openTeacherReport(row),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              foregroundColor: const Color(0xFF176CCB),
                              side: BorderSide(color: c.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(context.l10n.writeProgress, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              foregroundColor: const Color(0xFF176CCB),
                              side: BorderSide(color: c.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text(context.l10n.caseStudy, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onPressed: () => _openCaseDiscussion(childId: childId),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              foregroundColor: const Color(0xFF176CCB),
                              side: BorderSide(color: c.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.lightbulb_outline, size: 18),
                            label: Text(context.l10n.suggestSupport, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onPressed: () => _recommendLearningSupport(row),
                          ),
                        ),
                      ],
                    ),
                    if (child['current_plan_id'] != null || current != null) ...[
                      const SizedBox(height: 10),
                      LayoutBuilder(builder: (context, constraints) {
                        final actionWidth = (constraints.maxWidth - 10) / 2;
                        return Wrap(spacing: 10, runSpacing: 10, children: [
                        if (child['current_plan_id'] != null) SizedBox(
                        width: actionWidth,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                              side: BorderSide(color: c.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(AppIcons.evaluate, size: 17),
                          label: Text(context.l10n.evaluateCurrentPlan),
                          onPressed: () => _openPlanEvaluation(row),
                        ),
                      ),
                        if (current != null) SizedBox(
                        width: actionWidth,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                              side: BorderSide(color: c.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: approving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(AppIcons.check, size: 17),
                          label: Text(approving ? context.l10n.approving : context.l10n.approveCurrentActivity),
                          onPressed: approving ? null : () => _approve(row),
                        ),
                      ),

                        ]);
                      }),
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
