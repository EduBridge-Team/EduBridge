part of 'teacher_screen.dart';

extension _TeacherChildCardView on _TeacherChildCardState {
  Widget buildView(BuildContext context) {
    final name = (child['name'] ?? '').toString();
    final progress = _progressPercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.line, width: 1.2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '؟',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _followStatus,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${progress.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.brandBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        AppIcons.starFilled,
                        size: 20,
                        color: AppColors.brandTeal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: () => _openProfile(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.folder_open_rounded, size: 23),
                      label: const Text(
                        'فتح ملف الطالب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: () => _openApprovedPlan(context, child),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandBlue,
                        side: BorderSide(color: c.line, width: 1.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(AppIcons.view, size: 22),
                      label: const Text(
                        'الخطة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.brandBlue,
                      size: 23,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'إجراءات سريعة',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: c.heading,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.brandBlue,
                      size: 27,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              secondChild: const SizedBox.shrink(),
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            context: context,
                            icon: AppIcons.report,
                            label: 'التقارير',
                            color: AppColors.brandBlue,
                            onTap: () => _openDetailsTab(context, 2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickAction(
                            context: context,
                            icon: AppIcons.edit,
                            label: 'الواجبات',
                            color: AppColors.brandBlue,
                            onTap: () => _openDetailsTab(context, 0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            context: context,
                            icon: AppIcons.forum,
                            label: 'دراسة الحالة',
                            color: AppColors.brandBlue,
                            onTap: () => _openDetailsTab(context, 3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickAction(
                            context: context,
                            icon: AppIcons.lesson,
                            label: 'الدروس',
                            color: AppColors.brandBlue,
                            onTap: () => _openDetailsTab(context, 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: c.card,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChildProgressScreen(
                              childId: child['id'] as int,
                              childName: name,
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          minHeight: 62,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.purple.withValues(alpha: .55),
                              width: 1.4,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                AppIcons.specialist,
                                size: 22,
                                color: AppColors.purple,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'التقدم',
                                style: TextStyle(
                                  color: c.heading,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
