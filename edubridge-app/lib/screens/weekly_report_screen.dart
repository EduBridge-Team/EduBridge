// lib/screens/weekly_report_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../model/weekly_report_model.dart';
import '../model/specialist_weekly_evaluation.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
part 'weekly_report_view.dart';
part 'weekly_report_s26.dart';

class WeeklyReportScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final DateTime? weekStart;
  final bool specialistS26;

  const WeeklyReportScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.weekStart,
    this.specialistS26 = false,
  });

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  WeeklyReport? _report;
  List<WeeklyReport> _history = [];
  DateTime? _selectedWeek;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.weekStart;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _report = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getWeeklyReport(
          childId: widget.childId,
          weekStart: _selectedWeek,
        ),
        ApiService.getChildWeeklyReports(widget.childId),
      ]);
      final data = results[0] as Map<String, dynamic>?;
      final history = (results[1] as List)
          .map((row) => WeeklyReport.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _history = history;
        _report = data != null ? WeeklyReport.fromJson(data) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = SharedUiMessage.reportLoadFailed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.specialistS26 || ApiService.userRole.value == 'specialist'
          ? buildS26(context)
          : buildView(context);

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(AppIcons.error, size: 56, color: AppColors.red),
        const SizedBox(height: 14),
        Text(
          context.sharedMessage(_error),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            icon: const Icon(AppIcons.refresh),
            label: Text(context.l10n.retryAction),
            onPressed: _load,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final c = JisrColors.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: c.tintTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.report,
              size: 40,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.reportEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: c.heading,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.reportEmptyHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: c.muted),
        ),
      ],
    );
  }

  Widget _buildReport() {
    final r = _report!;
    final c = JisrColors.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              const Icon(AppIcons.calendar, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(
                context.l10n.reportWeekRange(MaterialLocalizations.of(context).formatShortDate(r.weekStart), MaterialLocalizations.of(context).formatShortDate(r.weekEnd)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${r.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                context.l10n.reportProgress,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            _statCard(
              icon: AppIcons.lesson,
              label: context.l10n.lessons,
              value: '${r.lessonsCompleted}/${r.lessonsTotal}',
              color: AppColors.brandTeal,
            ),
            const SizedBox(width: 8),
            _statCard(
              icon: AppIcons.homework,
              label: context.l10n.homeworks,
              value: '${r.homeworkSubmitted}/${r.homeworkAssigned}',
              color: AppColors.orange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard(
              icon: AppIcons.specialist,
              label: context.l10n.reportSupportMeetings,
              value:
                  '${r.learningSupportMeetingsAttended}/${r.learningSupportMeetingsScheduled}',
              color: AppColors.pink,
            ),
            const SizedBox(width: 8),
            _statCard(
              icon: AppIcons.check,
              label: context.l10n.achievement,
              value: '${(r.homeworkRate * 100).toStringAsFixed(0)}%',
              color: AppColors.green,
            ),
          ],
        ),

        if (r.teacherNotes != null && r.teacherNotes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _noteCard(
            icon: AppIcons.teacher,
            title: context.l10n.reportTeacherNote,
            content: r.teacherNotes!,
            color: c.tintTeal,
          ),
        ],

        if (r.specialistNotes != null && r.specialistNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _noteCard(
            icon: AppIcons.specialist,
            title: context.l10n.reportSpecialistEvaluation,
            content: r.specialistNotes!,
            color: c.tintOrange,
          ),
        ],

        if (r.achievements.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(AppIcons.trophy,
                  size: 22, color: AppColors.yellow),
              const SizedBox(width: 8),
              Expanded(child: Text(
                context.l10n.reportAchievements,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              )),
            ],
          ),
          const SizedBox(height: 8),
          ...r.achievements.map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.starFilled, color: AppColors.yellow),
                  const SizedBox(width: 9),
                  Expanded(child: Text(a)),
                ],
              ),
            ),
          ),
        ],

        if (r.concerns.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(AppIcons.warning,
                  size: 22, color: AppColors.orangeDeep),
              const SizedBox(width: 8),
              Expanded(child: Text(
                context.l10n.reportConcerns,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              )),
            ],
          ),
          const SizedBox(height: 8),
          ...r.concerns.map(
            (cn) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.red.withValues(alpha: .18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.warning, color: AppColors.red),
                  const SizedBox(width: 9),
                  Expanded(child: Text(cn)),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _noteCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Expanded(child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              )),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
