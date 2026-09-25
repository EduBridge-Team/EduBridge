// Parent dashboard presentation widgets extracted from parent_screen.dart.
part of 'parent_screen.dart';

extension _ParentScreenWidgetsExtension on _ParentScreenState {
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

    return ListView.builder(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      itemCount: _children.length,
      itemBuilder: (context, i) => _buildChildCard(_children[i], i),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
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

            // ─── الصف 1 ───
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: 'الواجبات',
                    icon: AppIcons.homework,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.orange,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openHomework(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'التقرير',
                    icon: AppIcons.report,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandTeal,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openWeeklyReport(child),
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

            // ─── الصف 2 ───
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: 'التقدّم',
                    icon: AppIcons.progress,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.green,
                    fullWidth: true,
                    onPressed: () => _openChildProgress(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'تعديل',
                    icon: AppIcons.edit,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandBlue,
                    fullWidth: true,
                    onPressed: () => _openEditChild(child),
                  ),
                ),
              ],
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ─── دروس لولي الأمر ───
            AdaptiveButton(
              label: 'دروس لولي الأمر',
              icon: AppIcons.parent,
              backgroundColor: AppColors.purple,
              onPressed: _openParentLessons,
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ─── طلب جلسة دعم تعليمي ───
            AdaptiveButton(
              label: 'طلب جلسة دعم تعليمي',
              icon: AppIcons.specialist,
              backgroundColor: AppColors.brandTeal,
              onPressed: () => _openLearningSupportRequest(child),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildStatusBadge(String? status) {
    final (text, color, icon) = switch (status) {
      'evaluated' => ('تم التقييم', AppColors.green, AppIcons.check),
      'assigned' => ('تم التعيين', AppColors.brandBlue, AppIcons.verified),
      _ => ('قيد الانتظار', AppColors.orange, AppIcons.clock),
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
}
