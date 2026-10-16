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
    final average = _summary?['avg_score'];
    final total = done + inProgress + notStarted;
    final percent = total == 0 ? 0.0 : done / total;

    return Column(children: [
      _s09Card(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نسبة الإنجاز', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: Color(0xFF637E98))),
              const SizedBox(height: 10),
              Text(
                total == 0 ? 'لم يبدأ ${widget.childName} دروسه بعد'
                    : done == total
                        ? 'أنهى ${widget.childName} جميع دروسه'
                        : 'أكمل ${widget.childName} ${(100 * percent).round()}% من دروسه',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  height: 1.4, color: Color(0xFF102D49))),
              const SizedBox(height: 8),
              Text('${done} من ${total} درس مكتمل', style: const TextStyle(
                fontSize: 12, color: Color(0xFF637E98))),
              if (average != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FA),
                    borderRadius: BorderRadius.circular(18)),
                  child: Text('المستوى: ${average}%', style: const TextStyle(
                    color: Color(0xFF637E98), fontSize: 11)),
                ),
              ],
            ],
          )),
          const SizedBox(width: 15),
          SizedBox(width: 96, height: 96,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: percent, strokeWidth: 9, strokeCap: StrokeCap.round,
                color: const Color(0xFF53B357),
                backgroundColor: const Color(0xFFE7F0F7))),
              Text('${(percent * 100).round()}%', style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: Color(0xFF102D49))),
            ])),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        _summaryCard('مكتمل', '${done}', Icons.check_circle_outline,
          const Color(0xFF53B357)),
        const SizedBox(width: 8),
        _summaryCard('قيد التنفيذ', '${inProgress}', Icons.autorenew_rounded,
          const Color(0xFF1CB6C4)),
        const SizedBox(width: 8),
        _summaryCard('لم يبدأ', '${notStarted}', Icons.access_time_rounded,
          const Color(0xFF6C88A4)),
        const SizedBox(width: 8),
        _summaryCard('متوسط', average == null ? '—' : '${average}%',
          Icons.star_rounded, const Color(0xFFFFB72E)),
      ]),
    ]);
  }

  Widget _summaryCard(String label, String value, IconData icon, Color tint) {
    return Expanded(child: Container(
      height: 127,
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD8E6F2))),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(radius: 19,
          backgroundColor: tint.withValues(alpha: 0.12),
          child: Icon(icon, size: 21, color: tint)),
        Text(value, maxLines: 1, style: const TextStyle(
          color: Color(0xFF102D49), fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, maxLines: 1, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Color(0xFF102D49))),
      ]),
    ));
  }

  Widget _buildRewardsSection() {
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;
    return Column(children: [
      _s09Title('المكافآت', trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white,
          border: Border.all(color: const Color(0xFFD8E6F2)),
          borderRadius: BorderRadius.circular(23)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 18,
            color: Color(0xFFFFB72E)),
          const SizedBox(width: 4),
          Text('${_stars} نجمة', style: const TextStyle(
            fontSize: 11, color: Color(0xFF102D49))),
        ]),
      )),
      const SizedBox(height: 12),
      Row(children: [
        _s09BadgeCard('البداية المشرقة', done, 1),
        const SizedBox(width: 9),
        _s09BadgeCard('نجمة المثابرة', done, 4),
        const SizedBox(width: 9),
        _s09BadgeCard('بطل الدروس', done, 9),
      ]),
    ]);
  }

  Widget _s09BadgeCard(String title, int done, int goal) {
    final earned = done >= goal;
    final achieved = done.clamp(0, goal);
    return Expanded(child: Container(
      height: 179,
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 11),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: earned ? const Color(0xFF53B357)
          : const Color(0xFFD8E6F2))),
      child: Column(children: [
        CircleAvatar(radius: 24,
          backgroundColor: earned ? const Color(0xFFE7F5E9)
            : const Color(0xFFF0F6FA),
          child: Icon(earned ? Icons.emoji_events_outlined
            : Icons.lock_outline, size: 26,
            color: earned ? const Color(0xFF53B357)
              : const Color(0xFF6C88A4))),
        const SizedBox(height: 10),
        Expanded(child: Center(child: Text(title, textAlign: TextAlign.center,
          maxLines: 2, style: const TextStyle(
            color: Color(0xFF102D49), fontSize: 11,
            height: 1.4, fontWeight: FontWeight.w800)))),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: achieved / goal, minHeight: 4,
            color: const Color(0xFF53B357),
            backgroundColor: const Color(0xFFE1EDF6))),
        const SizedBox(height: 8),
        Text(earned ? 'تم الإنجاز' : '${achieved}/${goal}',
          style: TextStyle(fontSize: 10,
            color: earned ? const Color(0xFF53B357)
              : const Color(0xFF637E98))),
      ]),
    ));
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
