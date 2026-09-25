// lib/screens/specialist/specialist_child_cards.dart
part of 'specialist_screen.dart';

extension _ChildCardsExtension on _SpecialistDashboardScreenState {
  // ═══════════════════════════════════════════════════════════
  //  بطاقة الطفل "المتاح" (قائمة الانتظار)
  // ═══════════════════════════════════════════════════════════
  Widget buildAvailableChildCard(Map<String, dynamic> row, JisrColors c) {
    final child = row['child'] as Map<String, dynamic>;
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final disability = (child['disability_type'] ?? '').toString();
    final description = (child['disability_description'] ?? '').toString();
    final medicalHistory = (child['medical_history'] ?? '').toString();
    final strengths = (child['strengths'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final challenges = (child['challenges'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final preferredStyle =
        (child['preferred_learning_style'] ?? '').toString();
    final specialNeeds = (child['special_needs'] ?? '').toString();

    final color = AppColors
        .kidPalette[_rows.indexOf(row) % AppColors.kidPalette.length];
    final isAdding = _approvingId == child['id'];
    final hasSpecialty = _mySpecialty != null;

    final specType = _mySpecialty == 'learning_support'
        ? 'مختص دعم تعليمي'
        : _mySpecialty == 'educational'
            ? 'مختص تعليمي'
            : 'مختص (تخصصك غير محدد)';

    final specIcon = _mySpecialty == 'learning_support'
        ? AppIcons.specialist
        : AppIcons.lesson;

    final specColor = _mySpecialty == 'learning_support'
        ? AppColors.purple
        : AppColors.brandBlue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          )),
                      Text(
                        'العمر: $age سنة'
                        '${disability.isNotEmpty ? ' • $disability' : ''}',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('متاح',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty)
              _infoRowExt('وصف الإعاقة', description, c),
            if (medicalHistory.isNotEmpty)
              _infoRowExt('التاريخ الطبي', medicalHistory, c),
            if (specialNeeds.isNotEmpty)
              _infoRowExt('احتياجات خاصة', specialNeeds, c),
            if (preferredStyle.isNotEmpty)
              _infoRowExt('أسلوب التعلم', preferredStyle, c),
            if (strengths.isNotEmpty)
              _chipsRowExt('نقاط القوة', strengths, c, AppColors.greenDeep,
                  c.tintGreen),
            if (challenges.isNotEmpty)
              _chipsRowExt('التحديات', challenges, c, AppColors.orangeDeep,
                  c.tintOrange),
            const SizedBox(height: 12),

            if (!hasSpecialty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(AppIcons.info, size: 20),
                  label: const Text(
                    'حدد تخصصك أولاً',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChooseSpecialtyScreen(),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _mySpecialty = result);
                    }
                  },
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: specColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(specIcon, size: 20),
                  label: Text(
                    isAdding ? 'جارٍ الإضافة...' : 'أضفني كـ$specType',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed:
                      isAdding ? null : () => _addMyselfToChild(child),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  بطاقة "طفلي"
  // ═══════════════════════════════════════════════════════════
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