// Parent dashboard presentation widgets extracted from parent_screen.dart.
part of 'parent_screen.dart';

extension _ParentScreenWidgetsExtension on _ParentScreenState {
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: FutureBuilder<String?>(
        future: ApiService.getName(),
        builder: (context, snap) {
          final name = snap.data ?? 'ولي الأمر';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProfileAvatarButton(
                size: 52,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandTealDeep,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      'مرحباً، $name',
                      type: AdaptiveTextType.title,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    const SizedBox(height: 4),
                    AdaptiveText(
                      'تابع أطفالك وتقدّمهم التعليمي من مكان واحد',
                      type: AdaptiveTextType.caption,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

    final c = JisrColors.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 108),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'أطفالك',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.heading,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_children.length} ${_children.length == 1 ? 'طفل' : 'أطفال'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'وصول سريع للواجبات والتقارير والتقدّم وفريق الرعاية.',
          style: TextStyle(
            fontSize: 13.5,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          _children.length,
          (i) => _buildChildCard(_children[i], i),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 110),
        const Icon(AppIcons.error, size: 58, color: AppColors.red),
        const SizedBox(height: 14),
        AdaptiveText(
          _error!,
          textAlign: TextAlign.center,
          color: AppColors.red,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            onPressed: _loadData,
            icon: const Icon(AppIcons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final c = JisrColors.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: c.tintTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 42,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        const SizedBox(height: 18),
        AdaptiveText(
          'لا يوجد أطفال مسجلون بعد',
          type: AdaptiveTextType.subtitle,
          textAlign: TextAlign.center,
          fontWeight: FontWeight.w800,
          color: c.heading,
        ),
        const SizedBox(height: 6),
        AdaptiveText(
          'أضف طفلك للبدء بمتابعة الدروس والتقدّم وفريق الرعاية.',
          type: AdaptiveTextType.caption,
          textAlign: TextAlign.center,
          color: c.muted,
        ),
      ],
    );
  }

  Widget _buildChildCard(Map child, int index) {
    final c = JisrColors.of(context);
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final status = child['status'];
    final disabilityType = (child['disability_type'] ?? '').toString().trim();
    final color = AppColors.kidPalette[index % AppColors.kidPalette.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openChildDetails(child),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(name, color),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: c.heading,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _infoChip(
                                icon: Icons.cake_outlined,
                                text: '$age سنة',
                                c: c,
                              ),
                              if (disabilityType.isNotEmpty)
                                _infoChip(
                                  icon: Icons.accessibility_new_rounded,
                                  text: disabilityType,
                                  c: c,
                                ),
                            ],
                          ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _quickAction(
                        icon: AppIcons.homework,
                        label: 'الواجب',
                        color: AppColors.brandBlue,
                        onTap: () => _openHomework(child),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quickAction(
                        icon: AppIcons.report,
                        label: 'التقرير',
                        color: AppColors.brandTeal,
                        onTap: () => _openWeeklyReport(child),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quickAction(
                        icon: AppIcons.users,
                        label: 'الفريق',
                        color: AppColors.brandBlue,
                        onTap: () => _openCareTeam(child),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quickAction(
                        icon: AppIcons.progress,
                        label: 'التقدّم',
                        color: AppColors.brandTealDeep,
                        onTap: () => _openChildProgress(child),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _secondaryAction(
                        icon: AppIcons.parent,
                        label: 'دروس ولي الأمر',
                        onTap: _openParentLessons,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _secondaryAction(
                        icon: AppIcons.specialist,
                        label: 'طلب دعم تعليمي',
                        onTap: () => _openLearningSupportRequest(child),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => _openEditChild(child),
                    icon: const Icon(AppIcons.edit, size: 17),
                    label: const Text(
                      'تعديل البيانات',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final c = JisrColors.of(context);

    return Material(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: c.heading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final c = JisrColors.of(context);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(color: c.line),
        foregroundColor: AppColors.brandBlue,
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
    required JisrColors c,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.tintTeal.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, Color color) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(19),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.characters.first : '؟',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final (text, color, icon) = switch (status) {
      'evaluated' => ('تم التقييم', AppColors.brandTealDeep, AppIcons.check),
      'assigned' => ('تم التعيين', AppColors.brandBlue, AppIcons.verified),
      _ => ('قيد الانتظار', AppColors.orangeDeep, AppIcons.clock),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
