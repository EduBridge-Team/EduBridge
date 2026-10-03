part of 'teacher_child_details_screen.dart';

class _TeacherReportsTab extends StatefulWidget {
  final int childId;
  final String childName;

  const _TeacherReportsTab({
    required this.childId,
    required this.childName,
  });

  @override
  State<_TeacherReportsTab> createState() => _TeacherReportsTabState();
}

class _TeacherReportsTabState extends State<_TeacherReportsTab> {
  List<WeeklyReport> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.getChildWeeklyReports(widget.childId);
      final reports = raw
          .map((e) => WeeklyReport.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.weekStart.compareTo(a.weekStart));

      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل التقارير';
        _loading = false;
      });
    }
  }

  Future<void> _createReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWeeklyReportScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openReport(WeeklyReport report) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyReportScreen(
          childId: widget.childId,
          childName: widget.childName,
          weekStart: report.weekStart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: Column(
                      children: [
                        const Icon(AppIcons.error, size: 52, color: AppColors.red),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(AppIcons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                else if (_reports.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: Column(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: c.tintTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.report,
                            size: 38,
                            color: AppColors.brandBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد تقارير بعد',
                          style: TextStyle(
                            color: c.heading,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اكتب أول تقرير أسبوعي لهذا الطالب.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.muted, fontSize: 13.5),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        'كل التقارير',
                        style: TextStyle(
                          color: c.heading,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.tintTeal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_reports.length}',
                          style: const TextStyle(
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._reports.map((report) => _ReportTile(
                        report: report,
                        onTap: () => _openReport(report),
                      )),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'create-report-${widget.childId}',
            onPressed: _createReport,
            icon: const Icon(AppIcons.add),
            label: const Text(
              'كتابة تقرير',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  final WeeklyReport report;
  final VoidCallback onTap;

  const _ReportTile({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final start = report.weekStart;
    final end = report.weekEnd;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  AppIcons.report,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقرير الأسبوع ${start.day}/${start.month} — ${end.day}/${end.month}',
                      style: TextStyle(
                        color: c.heading,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'نسبة التقدّم ${report.progressPercentage.toStringAsFixed(0)}%  •  الدروس ${report.lessonsCompleted}/${report.lessonsTotal}',
                      style: TextStyle(color: c.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_left, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}
