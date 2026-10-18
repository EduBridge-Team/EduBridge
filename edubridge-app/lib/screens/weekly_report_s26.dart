part of 'weekly_report_screen.dart';

const _reportBlue = Color(0xFF1769C2);
const _reportTeal = Color(0xFF04ACC0);

extension _WeeklyReportS26 on _WeeklyReportScreenState {
  Widget buildS26(BuildContext context) {
    final c = JisrColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F9FC),
        appBar: BrandAppBar(
          toolbarHeight: 96,
          centerTitle: false,
          titleSpacing: 0,
          leadingWidth: 52,
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: () => Navigator.maybePop(context),
            icon: const CircleAvatar(radius: 19,
              backgroundColor: Color(0x33FFFFFF),
              child: Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white))),
          title: Text('تقرير ${widget.childName} الأسبوعي',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white,
              fontSize: 19, fontWeight: FontWeight.w800)),
        ),
        body: SafeArea(top: false, child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null || _report == null ? Column(children: [
                  Padding(padding: const EdgeInsets.all(12), child: _reportWeek(c)),
                  Expanded(child: _error != null ? _buildError() : _buildEmpty()),
                ])
              : _s26Report(c, _report!),
        )),
      ),
    );
  }

  Widget _reportWeek(JisrColors c, {bool onBlue = false}) {
    final r = _report;
    final weeks = {
      if (_selectedWeek != null) _weekKey(_selectedWeek!),
      ..._history.map((report) => _weekKey(report.weekStart)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: onBlue ? const Color(0x33FFFFFF) : c.card,
        borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 210),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        isExpanded: true,
        key: const ValueKey('s26-week'),
        value: _selectedWeek == null ? '' : _weekKey(_selectedWeek!),
        isDense: true,
        dropdownColor: c.card,
        icon: Icon(Icons.access_time_rounded, size: 17,
          color: onBlue ? Colors.white : _reportBlue),
        selectedItemBuilder: (_) => [
          for (var i = 0; i <= weeks.length; i++)
            Text(r == null ? 'أسبوع التقرير' :
              'الأسبوع: ${r.weekStart.day}/${r.weekStart.month} — ${r.weekEnd.day}/${r.weekEnd.month}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: onBlue ? Colors.white : c.heading)),
        ],
        items: [
          const DropdownMenuItem(value: '', child: Text('الأسبوع الحالي')),
          for (final week in weeks)
            DropdownMenuItem(value: week, child: Text('الأسبوع الذي يبدأ في $week',
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (value) {
          _selectedWeek = value == null || value.isEmpty ? null : DateTime.parse(value);
          _load();
        },
      ))),
    );
  }

  Widget _s26Report(JisrColors c, WeeklyReport r) {
    final evaluation = SpecialistWeeklyEvaluation.fromNotes(r.specialistNotes);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF1DB5C6), Color(0xFF1458B6)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Align(alignment: AlignmentDirectional.centerStart,
              child: _reportWeek(c, onBlue: true)),
            const SizedBox(height: 24),
            Align(alignment: AlignmentDirectional.centerStart,
              child: Text('${r.progressPercentage.round()}%',
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white,
                  fontSize: 48, fontWeight: FontWeight.w900, height: 1))),
            const SizedBox(height: 6),
            const Center(child: Text('نسبة التقدّم',
              style: TextStyle(color: Colors.white70, fontSize: 13))),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (r.progressPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: const Color(0x44FFFFFF),
                color: const Color(0xFF63D6E0))),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _s26Stat(c, Icons.menu_book_outlined, 'الدروس',
            '${r.lessonsCompleted}/${r.lessonsTotal}', _reportTeal),
          const SizedBox(width: 8),
          _s26Stat(c, Icons.description_outlined, 'الواجبات',
            '${r.homeworkSubmitted}/${r.homeworkAssigned}', _reportTeal),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _s26Stat(c, Icons.psychology_outlined, 'اجتماعات الدعم',
            '${r.learningSupportMeetingsAttended}/${r.learningSupportMeetingsScheduled}',
            const Color(0xFFFF5685)),
          const SizedBox(width: 8),
          _s26Stat(c, Icons.task_alt_rounded, 'الإنجاز',
            '${(r.homeworkRate * 100).round()}%', const Color(0xFF69D78B)),
        ]),
        if (r.teacherNotes?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          _s26Card(c, 'ملاحظة المعلم', r.teacherNotes!),
        ],
        const SizedBox(height: 10),
        _s26Surface(c, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _s26Title(c, 'تقييم المختص', Icons.lightbulb_outline_rounded, _reportBlue),
          const SizedBox(height: 14),
          Text(evaluation.notes.isEmpty ? 'لا يوجد' : evaluation.notes,
            style: TextStyle(color: c.heading, fontSize: 13, height: 1.6)),
          const SizedBox(height: 12),
          _s26Detail(c, 'التوصيات', evaluation.recommendations.isEmpty
              ? 'لا يوجد' : evaluation.recommendations),
          Divider(color: c.line, height: 20),
          _s26Detail(c, 'ملاءمة الخطة', evaluation.suitability ?? '—'),
          if (evaluation.planChanges.isNotEmpty) ...[
            Divider(color: c.line, height: 20),
            _s26Detail(c, 'تقييم الخطة', evaluation.planChanges),
          ],
          Divider(color: c.line, height: 20),
          _s26Detail(c, 'تقييم التفاعل', evaluation.interaction ?? '—'),
        ])),
        if (r.parentNotes?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 10), _s26Card(c, 'ملاحظة ولي الأمر', r.parentNotes!),
        ],
        if (r.achievements.isNotEmpty) ...[
          const SizedBox(height: 16),
          _s26Title(c, 'الإنجازات', Icons.emoji_events_outlined, _reportTeal),
          for (final item in r.achievements) _s26Notice(c, item, positive: true),
        ],
        const SizedBox(height: 16),
        _s26Title(c, 'نقاط للانتباه', Icons.info_outline_rounded, _reportTeal),
        const SizedBox(height: 10),
        if (r.concerns.isEmpty) _s26Notice(c, 'لا يوجد', positive: true)
        else for (final concern in r.concerns) _s26Notice(c, concern, positive: false),
      ],
    );
  }

  Widget _s26Surface(JisrColors c, Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: c.card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x060F3658), blurRadius: 14)]),
    child: child,
  );

  Widget _s26Stat(JisrColors c, IconData icon, String label, String value, Color accent) =>
    Expanded(child: _s26Surface(c, Row(children: [
      Container(width: 38, height: 38,
        decoration: BoxDecoration(color: accent.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: accent, size: 23)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, textDirection: TextDirection.ltr, style: TextStyle(
          color: accent, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: c.muted, fontSize: 11)),
      ])),
    ])));

  Widget _s26Title(JisrColors c, String title, IconData icon, Color accent) => Row(children: [
    Icon(icon, color: accent, size: 18),
    const SizedBox(width: 8),
    Expanded(child: Text(title, style: TextStyle(color: c.heading,
      fontSize: 16, fontWeight: FontWeight.w800))),
  ]);

  Widget _s26Detail(JisrColors c, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: TextStyle(color: c.muted, fontSize: 12))),
      const SizedBox(width: 12),
      Expanded(child: Text(value, textAlign: TextAlign.end,
        style: TextStyle(color: c.heading, fontSize: 12, height: 1.5))),
    ],
  );

  Widget _s26Card(JisrColors c, String title, String body) => _s26Surface(c,
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _s26Title(c, title, Icons.description_outlined, _reportBlue),
      const SizedBox(height: 10), Text(body, style: TextStyle(color: c.heading)),
    ]));

  Widget _s26Notice(JisrColors c, String text, {required bool positive}) {
    final accent = positive ? const Color(0xFF69D78B) : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: accent.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Icon(positive ? Icons.check_rounded : Icons.info_outline, color: accent, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: positive ? c.successText : c.dangerText,
          fontSize: 13, height: 1.5))),
      ]),
    );
  }
}
