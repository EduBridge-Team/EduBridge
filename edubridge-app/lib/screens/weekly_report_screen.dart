// lib/screens/weekly_report_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../model/weekly_report_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

class WeeklyReportScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const WeeklyReportScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  WeeklyReport? _report;
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
      final data = await ApiService.getWeeklyReport(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _report = data != null ? WeeklyReport.fromJson(data) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل التقرير';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: 'تقرير ${widget.childName} الأسبوعي'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _report == null
                    ? _buildEmpty()
                    : _buildReport(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, size: 64, color: AppColors.red),
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(fontSize: 16, color: AppColors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(AppIcons.refresh),
            label: const Text('إعادة المحاولة'),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final c = JisrColors.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(AppIcons.homework, size: 80, color: c.muted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'لا يوجد تقرير أسبوعي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: c.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'سيظهر هنا التقرير الذي يكتبه المعلم',
            style: TextStyle(fontSize: 14, color: c.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildReport() {
    final r = _report!;
    final c = JisrColors.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(AppIcons.calendar, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(
                'الأسبوع: ${r.weekStart.day}/${r.weekStart.month} — '
                '${r.weekEnd.day}/${r.weekEnd.month}',
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'نسبة التقدّم',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            _statCard(
              icon: AppIcons.lesson,
              label: 'الدروس',
              value: '${r.lessonsCompleted}/${r.lessonsTotal}',
              color: AppColors.brandTeal,
            ),
            const SizedBox(width: 8),
            _statCard(
              icon: AppIcons.homework,
              label: 'الواجبات',
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
              label: 'اجتماعات الدعم',
              value:
                  '${r.learningSupportMeetingsAttended}/${r.learningSupportMeetingsScheduled}',
              color: AppColors.pink,
            ),
            const SizedBox(width: 8),
            _statCard(
              icon: AppIcons.check,
              label: 'الإنجاز',
              value: '${(r.homeworkRate * 100).toStringAsFixed(0)}%',
              color: AppColors.green,
            ),
          ],
        ),

        if (r.teacherNotes != null && r.teacherNotes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _noteCard(
            icon: AppIcons.teacher,
            title: 'ملاحظة المعلم',
            content: r.teacherNotes!,
            color: c.tintTeal,
          ),
        ],

        if (r.specialistNotes != null && r.specialistNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _noteCard(
            icon: AppIcons.specialist,
            title: 'تقييم المختص',
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
              const Text(
                'الإنجازات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...r.achievements.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(AppIcons.starFilled,
                      color: AppColors.yellow),
                  title: Text(a),
                ),
              )),
        ],

        if (r.concerns.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(AppIcons.warning,
                  size: 22, color: AppColors.orangeDeep),
              const SizedBox(width: 8),
              const Text(
                'نقاط للانتباه',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...r.concerns.map((cn) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: AppColors.red.withValues(alpha: 0.05),
                child: ListTile(
                  leading: const Icon(AppIcons.warning,
                      color: AppColors.red),
                  title: Text(cn),
                ),
              )),
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
                fontWeight: FontWeight.bold,
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
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}