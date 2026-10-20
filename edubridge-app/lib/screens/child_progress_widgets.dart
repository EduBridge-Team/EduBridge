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
          Text(_error == _ProgressLoadError.fetch ? context.l10n.childProgressFetchError : context.l10n.connectionFailed, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red)),
          const SizedBox(height: 14),
          Center(child: FilledButton(
            onPressed: _loadProgress, child: Text(context.l10n.retryAction))),
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
        _s09Title(context.l10n.studentLessonDetails),
        const SizedBox(height: 12),
        if (_progress.isEmpty)
          _s09Card(
            child: Text(context.l10n.childProgressEmpty,
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
            label: Text(context.l10n.childProgressSuggest,
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
    final names = [context.l10n.childProgressWeekday0, context.l10n.childProgressWeekday1, context.l10n.childProgressWeekday2, context.l10n.childProgressWeekday3, context.l10n.childProgressWeekday4, context.l10n.childProgressWeekday5, context.l10n.childProgressWeekday6];
    final counts = _s09WeeklyCounts();
    final maximum = counts.fold<int>(0, (v, n) => n > v ? n : v);
    return _s09Card(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
      child: Column(
        children: [
          _s09Title(context.l10n.childProgressWeekly, trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FC),
              borderRadius: BorderRadius.circular(18)),
            child: Text(context.l10n.childProgressThisWeek,
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
            Text(context.l10n.childProgressNoWeekly,
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
              Text(context.l10n.childProgressCompletion, style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: Color(0xFF637E98))),
              const SizedBox(height: 10),
              Text(
                total == 0 ? context.l10n.childProgressNotBegun(widget.childName)
                    : done == total
                        ? context.l10n.childProgressAllDone(widget.childName)
                        : context.l10n.childProgressPercent(widget.childName, (100 * percent).round().toString()),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  height: 1.4, color: Color(0xFF102D49))),
              const SizedBox(height: 8),
              Text(context.l10n.childProgressCompletedCount(done.toString(), total.toString()), style: const TextStyle(
                fontSize: 12, color: Color(0xFF637E98))),
              if (average != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FA),
                    borderRadius: BorderRadius.circular(18)),
                  child: Text(context.l10n.childProgressLevel(average.toString()), style: const TextStyle(
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
        _summaryCard(context.l10n.completedStatus, '$done', Icons.check_circle_outline,
          const Color(0xFF53B357)),
        const SizedBox(width: 8),
        _summaryCard(context.l10n.inProgress, '$inProgress', Icons.autorenew_rounded,
          const Color(0xFF1CB6C4)),
        const SizedBox(width: 8),
        _summaryCard(context.l10n.studentLessonNotStarted, '$notStarted', Icons.access_time_rounded,
          const Color(0xFF6C88A4)),
        const SizedBox(width: 8),
        _summaryCard(context.l10n.childProgressAverage, average == null ? '—' : '$average%',
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
      _s09Title(context.l10n.childProgressRewards, trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white,
          border: Border.all(color: const Color(0xFFD8E6F2)),
          borderRadius: BorderRadius.circular(23)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 18,
            color: Color(0xFFFFB72E)),
          const SizedBox(width: 4),
          Text(context.l10n.childProgressStars(_stars), style: const TextStyle(
            fontSize: 11, color: Color(0xFF102D49))),
        ]),
      )),
      const SizedBox(height: 12),
      Row(children: [
        _s09BadgeCard(context.l10n.childProgressFirstBadge, done, 1),
        const SizedBox(width: 9),
        _s09BadgeCard(context.l10n.childProgressPersistenceBadge, done, 4),
        const SizedBox(width: 9),
        _s09BadgeCard(context.l10n.childProgressChampionBadge, done, 9),
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
        Text(earned ? context.l10n.childProgressEarned : '$achieved/$goal',
          style: TextStyle(fontSize: 10,
            color: earned ? const Color(0xFF53B357)
              : const Color(0xFF637E98))),
      ]),
    ));
  }

  Widget _buildProgressTile(Map p) {
    final info = _statusInfo((p['status'] ?? 'not_started').toString());
    final title = (p['lesson_title'] ?? '').toString();
    final score = p['score'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SpecialistDashboardScreen(initialTab: 1))),
          child: _s09Card(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width: 49, height: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F0FB),
                  borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.menu_book_outlined,
                  color: Color(0xFF1969C5), size: 25)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15,
                      color: Color(0xFF102D49), fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: info.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18)),
                    child: Text(score == null ? info.label
                      : context.l10n.childProgressStatusScore(info.label, score.toString()),
                      style: TextStyle(color: info.color, fontSize: 11)),
                  ),
                ],
              )),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_left_rounded,
                color: Color(0xFF637E98)),
            ]),
          ),
        ),
      ),
    );
  }

  ({String label, IconData icon, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'done':
        return (
          label: context.l10n.completedStatus,
          icon: AppIcons.check,
          color: AppColors.green,
        );
      case 'in_progress':
        return (
          label: context.l10n.inProgress,
          icon: AppIcons.refresh,
          color: AppColors.orangeDeep,
        );
      default:
        return (
          label: context.l10n.studentLessonNotStarted,
          icon: AppIcons.clock,
          color: AppColors.muted,
        );
    }
  }
}
