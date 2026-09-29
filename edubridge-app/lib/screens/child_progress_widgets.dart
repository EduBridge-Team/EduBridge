part of 'child_progress_screen.dart';

extension _ChildProgressWidgets on _ChildProgressScreenState {
  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return ListView(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
        children: [
          SizedBox(height: AdaptiveHelper.spacing * 6),
          const Icon(AppIcons.error, size: 58, color: AppColors.red),
          SizedBox(height: AdaptiveHelper.spacing),
          AdaptiveText(
            _error!,
            textAlign: TextAlign.center,
            color: AppColors.red,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: AdaptiveHelper.spacing),
          Center(
            child: FilledButton.icon(
              onPressed: _loadProgress,
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (_progress.isEmpty) {
      final c = JisrColors.of(context);
      return ListView(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
        children: [
          SizedBox(height: AdaptiveHelper.spacing * 5),
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: c.tintTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.progress,
                size: 42,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          SizedBox(height: AdaptiveHelper.spacing),
          AdaptiveText(
            'لا يوجد تقدّم مسجّل بعد',
            type: AdaptiveTextType.subtitle,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w800,
            color: c.heading,
          ),
          SizedBox(height: AdaptiveHelper.spacing / 3),
          AdaptiveText(
            'ستظهر هنا نسبة الإنجاز والنتائج والمكافآت بعد بدء الدروس.',
            type: AdaptiveTextType.caption,
            textAlign: TextAlign.center,
            color: c.muted,
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AdaptiveHelper.spacing,
        AdaptiveHelper.spacing * 1.25,
        AdaptiveHelper.spacing,
        AdaptiveHelper.spacing * 2,
      ),
      children: [
        _buildSummaryCards(),
        SizedBox(height: AdaptiveHelper.spacing * 2),
        _buildRewardsSection(),
        SizedBox(height: AdaptiveHelper.spacing * 2),
        const AdaptiveText(
          'تفاصيل الدروس',
          type: AdaptiveTextType.title,
        ),
        SizedBox(height: AdaptiveHelper.spacing),
        ..._progress.map((p) => _buildProgressTile(p)),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;
    final inProgress = int.tryParse('${_summary?['in_progress'] ?? 0}') ?? 0;
    final notStarted = int.tryParse('${_summary?['not_started'] ?? 0}') ?? 0;
    final avgScore = _summary?['avg_score'];

    final total = done + inProgress + notStarted;
    final percent = total > 0 ? done / total : 0.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AdaptiveHelper.spacing),
          decoration: BoxDecoration(
            color: JisrColors.of(context).card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: JisrColors.of(context).line),
          ),
          child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  color: AppColors.green,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(percent * 100).round()}%',
                    style: TextStyle(
                      fontSize: AdaptiveHelper.titleFontSize + 10,
                      fontWeight: FontWeight.w800,
                      color: AdaptiveHelper.textColor(context),
                    ),
                  ),
                  const AdaptiveText(
                    'الإنجاز',
                    type: AdaptiveTextType.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
        SizedBox(height: AdaptiveHelper.spacing),
        Row(
          children: [
            _summaryCard('مكتمل', '$done', AppIcons.check, AppColors.green),
            SizedBox(width: AdaptiveHelper.spacing / 2),
            _summaryCard('قيد التنفيذ', '$inProgress', AppIcons.refresh,
                AppColors.orangeDeep),
          ],
        ),
        SizedBox(height: AdaptiveHelper.spacing / 2),
        Row(
          children: [
            _summaryCard('لم يبدأ', '$notStarted', AppIcons.clock,
                AppColors.muted),
            SizedBox(width: AdaptiveHelper.spacing / 2),
            _summaryCard(
              'متوسّط',
              avgScore != null ? '$avgScore%' : '—',
              AppIcons.starFilled,
              AppColors.yellow,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: AdaptiveCard(
        child: Column(
          children: [
            Icon(icon, size: AdaptiveHelper.iconSize, color: color),
            SizedBox(height: AdaptiveHelper.spacing / 4),
            Text(
              value,
              style: TextStyle(
                fontSize: AdaptiveHelper.titleFontSize,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            AdaptiveText(label, type: AdaptiveTextType.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection() {
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;

    final badges = <({String emoji, String title, bool earned, String hint})>[
      (
        emoji: '🌟',
        title: 'البداية المشرقة',
        earned: done >= 1,
        hint: 'أكمل أول درس',
      ),
      (
        emoji: '🏅',
        title: 'نجم المثابرة',
        earned: done >= 5,
        hint: done >= 5 ? '' : 'بقي ${5 - done} دروس',
      ),
      (
        emoji: '🏆',
        title: 'بطل الدروس',
        earned: done >= 10,
        hint: done >= 10 ? '' : 'بقي ${10 - done} دروس',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdaptiveText(
          'المكافآت',
          type: AdaptiveTextType.title,
        ),
        SizedBox(height: AdaptiveHelper.spacing),

        AdaptiveCard(
          child: Row(
            children: [
              Icon(AppIcons.starFilled,
                  size: AdaptiveHelper.iconSize, color: AppColors.yellow),
              SizedBox(width: AdaptiveHelper.spacing / 2),
              Expanded(
                child: AdaptiveText(
                  'جمع ${widget.childName} $_stars نجمة',
                  type: AdaptiveTextType.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AdaptiveHelper.spacing),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AdaptiveHelper.spacing / 2,
          crossAxisSpacing: AdaptiveHelper.spacing / 2,
          childAspectRatio: 1.4,
          children: badges.map((b) => _buildBadgeCard(b)).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(
      ({String emoji, String title, bool earned, String hint}) badge) {
    return AdaptiveCard(
      backgroundColor: badge.earned
          ? AppColors.green.withValues(alpha: 0.1)
          : AdaptiveHelper.cardColor(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.earned ? AppIcons.trophy : AppIcons.lock,
            size: AdaptiveHelper.iconSize + 8,
            color: badge.earned ? AppColors.green : AppColors.muted,
          ),
          SizedBox(height: AdaptiveHelper.spacing / 4),
          AdaptiveText(
            badge.title,
            type: AdaptiveTextType.caption,
            fontWeight: FontWeight.w800,
            textAlign: TextAlign.center,
            color: badge.earned ? AppColors.green : null,
          ),
          if (!badge.earned && badge.hint.isNotEmpty)
            AdaptiveText(
              badge.hint,
              type: AdaptiveTextType.label,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressTile(Map p) {
    final status = p['status'] ?? 'not_started';
    final statusInfo = _statusInfo(status);
    final score = p['score'];
    final title = (p['lesson_title'] ?? '').toString();

    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing / 2),
      child: AdaptiveCard(
        child: Row(
          children: [
            Icon(
              statusInfo.icon,
              size: AdaptiveHelper.iconSize,
              color: statusInfo.color,
            ),
            SizedBox(width: AdaptiveHelper.spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveText(
                    title,
                    type: AdaptiveTextType.body,
                    fontWeight: FontWeight.w800,
                  ),
                  AdaptiveText(
                    statusInfo.label +
                        (score != null ? ' • النتيجة: $score%' : ''),
                    type: AdaptiveTextType.caption,
                    color: statusInfo.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String label, IconData icon, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'done':
        return (
          label: 'مكتمل',
          icon: AppIcons.check,
          color: AppColors.green,
        );
      case 'in_progress':
        return (
          label: 'قيد التنفيذ',
          icon: AppIcons.refresh,
          color: AppColors.orangeDeep,
        );
      default:
        return (
          label: 'لم يبدأ',
          icon: AppIcons.clock,
          color: AppColors.muted,
        );
    }
  }
}
