// Parent dashboard presentation widgets extracted from parent_screen.dart.
part of 'parent_screen.dart';

extension _ParentScreenWidgetsExtension on _ParentScreenState {
  // ═══════════════════════════════════════════════════════════
  //  الهيدر
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String?>(
            future: ApiService.getName(),
            builder: (context, snap) {
              final name = snap.data ?? 'ولي الأمر';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveText(
                    'مرحباً $name',
                    type: AdaptiveTextType.title,
                    color: Colors.white,
                  ),
                  SizedBox(height: AdaptiveHelper.spacing / 3),
                  AdaptiveText(
                    'أضف أطفالك وتابع تقدمهم التعليمي',
                    type: AdaptiveTextType.caption,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  الجسم الرئيسي
  // ═══════════════════════════════════════════════════════════
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_children.isEmpty) {
      return _buildEmptyState();
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AdaptiveHelper.spacing,
        AdaptiveHelper.spacing,
        AdaptiveHelper.spacing,
        AdaptiveHelper.spacing + bottomInset + 100,
      ),
      itemCount: _children.length,
      itemBuilder: (context, i) => _buildChildCard(_children[i], i),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  حالات الخطأ
  // ═══════════════════════════════════════════════════════════
  Widget _buildErrorState() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AdaptiveHelper.spacing * 2,
          AdaptiveHelper.spacing * 2,
          AdaptiveHelper.spacing * 2,
          AdaptiveHelper.spacing * 2 + bottomInset + 100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: AdaptiveHelper.iconSize * 2,
              color: AppColors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveText(
              _error!,
              textAlign: TextAlign.center,
              color: AppColors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  حالة الفراغ
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AdaptiveHelper.spacing * 2,
          AdaptiveHelper.spacing * 2,
          AdaptiveHelper.spacing * 2,
          AdaptiveHelper.spacing * 2 + bottomInset + 100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: AdaptiveHelper.iconSize * 2,
              color: AppColors.muted,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            const AdaptiveText(
              'لا يوجد أطفال مسجلون بعد',
              type: AdaptiveTextType.subtitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),
            AdaptiveText(
              'اضغط على زر + لإضافة طفل جديد',
              type: AdaptiveTextType.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  بطاقة الطفل — تصميم مُحسّن (3 أزرار + قائمة)
  // ═══════════════════════════════════════════════════════════
  Widget _buildChildCard(Map child, int index) {
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final status = child['status'];
    final disabilityType = child['disability_type'] ?? 'غير محدد';
    final color = AppColors.kidPalette[index % AppColors.kidPalette.length];

    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        onTap: () => _openChildDetails(child),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── الرأس ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(name, color),
                SizedBox(width: AdaptiveHelper.spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveText(
                        name,
                        type: AdaptiveTextType.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: AdaptiveHelper.spacing / 4),
                      AdaptiveText(
                        'العمر: $age سنة',
                        type: AdaptiveTextType.caption,
                      ),
                      AdaptiveText(
                        'الإعاقة: $disabilityType',
                        type: AdaptiveTextType.caption,
                      ),
                      if (child['assigned_teacher_name'] != null)
                        AdaptiveText(
                          'المعلم: ${child['assigned_teacher_name']}',
                          type: AdaptiveTextType.caption,
                          color: AppColors.brandBlue,
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            SizedBox(height: AdaptiveHelper.spacing),

            // ═══ الإجراءات الأساسية — 3 فقط ═══
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: 'الواجب',
                    icon: AppIcons.homework,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.blue,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openHomework(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'التقدّم',
                    icon: AppIcons.progress,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandTealDeep,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openChildProgress(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'الفريق',
                    icon: AppIcons.users,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandBlue,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openCareTeam(child),
                  ),
                ),
              ],
            ),

            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ═══ زر "أفعال أخرى" — Bottom Sheet ═══
            AdaptiveButton(
              label: 'أفعال أخرى',
              icon: Icons.more_horiz,
              style: AdaptiveButtonStyle.outlined,
              backgroundColor: AppColors.muted,
              onPressed: () => _openMoreActionsSheet(child),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  Avatar
  // ═══════════════════════════════════════════════════════════
  Widget _buildAvatar(String name, Color color) {
    final size = AdaptiveHelper.avatarSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.characters.first : '؟',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  شارة الحالة
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatusBadge(String? status) {
    final (text, color, icon) = switch (status) {
      'evaluated' => ('تم التقييم', AppColors.brandTealDeep, AppIcons.check),
      'assigned' => ('تم التعيين', AppColors.brandBlue, AppIcons.verified),
      _ => ('قيد الانتظار', AppColors.brandGreen, AppIcons.clock),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: AdaptiveHelper.bodyFontSize - 4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  Bottom Sheet — "أفعال أخرى"
  // ═══════════════════════════════════════════════════════════
  Future<void> _openMoreActionsSheet(Map child) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChildActionsSheet(
        childName: (child['name'] ?? '').toString(),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'report':
        _openWeeklyReport(child);
        break;
      case 'edit':
        _openEditChild(child);
        break;
      case 'parent_lessons':
        _openParentLessons();
        break;
      case 'support_request':
        _openLearningSupportRequest(child);
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  Bottom Sheet — قائمة الأفعال الثانوية
// ═══════════════════════════════════════════════════════════
class _ChildActionsSheet extends StatelessWidget {
  final String childName;
  const _ChildActionsSheet({required this.childName});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    final actions =
        <({String id, IconData icon, String label, Color color})>[
      (
        id: 'report',
        icon: AppIcons.report,
        label: 'التقرير الأسبوعي',
        color: AppColors.brandTeal,
      ),
      (
        id: 'edit',
        icon: AppIcons.edit,
        label: 'تعديل البيانات',
        color: AppColors.brandBlueDeep,
      ),
      (
        id: 'parent_lessons',
        icon: AppIcons.parent,
        label: 'دروس لولي الأمر',
        color: AppColors.brandTealDeep,
      ),
      (
        id: 'support_request',
        icon: AppIcons.specialist,
        label: 'طلب جلسة دعم تعليمي',
        color: AppColors.purple,
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── المقبض ───
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ─── العنوان ───
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.more_horiz,
                    color: AppColors.brandBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'أفعال أخرى',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        childName,
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── الإجراءات ───
            ...actions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, a.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: a.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(a.icon, color: a.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              a.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: c.heading,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_left,
                            color: c.muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}