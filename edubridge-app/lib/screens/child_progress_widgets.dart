part of 'child_progress_screen.dart';

extension _ChildProgressWidgets on _ChildProgressScreenState {
  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.error_outline, color: AppColors.red, size: 52),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red)),
          const SizedBox(height: 14),
          Center(child: FilledButton(
            onPressed: _loadProgress, child: const Text('إعادة المحاولة'))),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 14),
        _buildWeeklyActivity(),
        const SizedBox(height: 18),
        _buildRewardsSection(),
        const SizedBox(height: 24),
        _s09Title('تفاصيل الدروس'),
        const SizedBox(height: 12),
        if (_progress.isEmpty)
          _s09Card(
            child: const Text('لم يبدأ الطفل أي درس بعد. ستظهر تفاصيل الدروس هنا عند البدء.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF637E98))),
          )
        else
          ..._progress.whereType<Map>().map(_buildProgressTile),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1969C5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) =>
                const SpecialistDashboardScreen(initialTab: 1))),
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('اقترح درسًا تاليًا',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _s09Card({required Widget child, EdgeInsets? padding,
      Color border = const Color(0xFFD8E6F2)}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border)),
      child: child,
    );
  }

  Widget _s09Title(String title, {Widget? trailing}) => Row(
    children: [
      Expanded(child: Text(title, style: const TextStyle(
        fontSize: 21, color: Color(0xFF102D49), fontWeight: FontWeight.w800))),
      if (trailing != null) trailing,
    ],
  );

  List<int> _s09WeeklyCounts() {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday + 1) % 7));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final counts = List<int>.filled(7, 0);
    for (final row in _progress) {
      if (row is! Map || row['status'] != 'done') continue;
      final date = DateTime.tryParse(row['completed_at']?.toString() ?? '')?.toLocal();
      if (date == null || date.isBefore(weekStart) || !date.isBefore(weekEnd)) continue;
      final day = DateTime(date.year, date.month, date.day);
      counts[day.difference(weekStart).inDays] += 1;
    }
    return counts;
  }

  Widget _buildWeeklyActivity() {
    const names = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
    final counts = _s09WeeklyCounts();
    final maximum = counts.fold<int>(0, (v, n) => n > v ? n : v);
    return _s09Card(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
      child: Column(
        children: [
          _s09Title('نشاط الأسبوع', trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FC),
              borderRadius: BorderRadius.circular(18)),
            child: const Text('هذا الأسبوع',
              style: TextStyle(fontSize: 11, color: Color(0xFF1969C5))),
          )),
          const SizedBox(height: 13),
          Row(children: List.generate(7, (i) {
            final fraction = maximum == 0 ? 0.0 : counts[i] / maximum;
            return Expanded(child: Column(children: [
              SizedBox(height: 67, child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(width: 20, height: 67,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5FA),
                      borderRadius: BorderRadius.circular(7))),
                  if (counts[i] > 0)
                    Container(width: 20, height: 10 + fraction * 57,
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFF21BEC4)
                          : const Color(0xFF1969C5),
                        borderRadius: BorderRadius.circular(7))),
                ],
              )),
              const SizedBox(height: 7),
              Text(names[i], maxLines: 1,
                style: const TextStyle(fontSize: 10, color: Color(0xFF637E98))),
            ]));
          })),
          if (maximum == 0) ...[
            const SizedBox(height: 7),
            const Text('لا توجد دروس مكتملة هذا الأسبوع',
              style: TextStyle(fontSize: 10, color: Color(0xFF637E98))),
          ],
        ],
      ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JisrColors.of(context).card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: JisrColors.of(context).line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        color: AppColors.green,
                        backgroundColor: JisrColors.of(context).line,
                      ),
                    ),
                    Text('${(percent * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdaptiveText('نسبة الإنجاز', type: AdaptiveTextType.caption),
                    const SizedBox(height: 7),
                    AdaptiveText(
                      total == 0 ? 'لم يبدأ ${widget.childName} دروسه بعد'
                        : 'أكمل ${widget.childName} ${(percent * 100).round()}% من دروسه',
                      fontWeight: FontWeight.w800,
                    ),
                    const SizedBox(height: 7),
                    AdaptiveText('$done من أصل $total درس مكتمل',
                      type: AdaptiveTextType.caption),
                    if (avgScore != null) ...[
                      const SizedBox(height: 7),
                      AdaptiveText('المستوى: $avgScore%',
                        type: AdaptiveTextType.caption),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AdaptiveHelper.spacing),
        Row(
          children: [
            _summaryCard('مكتمل', '$done', AppIcons.check, AppColors.green),
            const SizedBox(width: 6),
            _summaryCard('قيد التنفيذ', '$inProgress', AppIcons.refresh,
                AppColors.brandBlue),
            const SizedBox(width: 6),
            _summaryCard('لم يبدأ', '$notStarted', AppIcons.clock, AppColors.muted),
            const SizedBox(width: 6),
            _summaryCard('متوسّط',
                avgScore != null ? '$avgScore%' : '—',
                AppIcons.starFilled, AppColors.yellow),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 126,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: JisrColors.of(context).card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JisrColors.of(context).line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 19, color: color),
            ),
            SizedBox(height: AdaptiveHelper.spacing / 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AdaptiveHelper.textColor(context),
              ),
            ),
            Text(label, maxLines: 1, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10)),
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
                  '$_stars نجمة',
                  type: AdaptiveTextType.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AdaptiveHelper.spacing),

        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AdaptiveHelper.spacing / 2,
          crossAxisSpacing: AdaptiveHelper.spacing / 2,
          childAspectRatio: 0.78,
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
