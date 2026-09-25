// lib/screens/create_specialist_progress_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../model/weekly_report_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
part 'create_specialist_progress_view.dart';

class CreateSpecialistProgressScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const CreateSpecialistProgressScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<CreateSpecialistProgressScreen> createState() =>
      _CreateSpecialistProgressScreenState();
}

class _CreateSpecialistProgressScreenState
    extends State<CreateSpecialistProgressScreen> {
  final _formKey = GlobalKey<FormState>();

  WeeklyReport? _teacherReport;
  bool _loadingReport = true;

  final _notesCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();
  final _planEvalCtrl = TextEditingController();
  bool _planAppropriate = true;
  int _moodRating = 3;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeacherReport();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _recommendationsCtrl.dispose();
    _planEvalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherReport() async {
    setState(() => _loadingReport = true);
    try {
      final data = await ApiService.getWeeklyReport(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _teacherReport = data != null ? WeeklyReport.fromJson(data) : null;
        _loadingReport = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReport = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.authPost('/reports/weekly/specialist', {
        'child_id': widget.childId,
        'specialist_notes': _notesCtrl.text.trim(),
        'recommendations': _recommendationsCtrl.text.trim(),
        'is_plan_appropriate': _planAppropriate,
        'plan_evaluation': _planEvalCtrl.text.trim(),
        'mood_rating': _moodRating,
      });

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ تقدّم الطفل'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = 'فشل الحفظ';
          _saving = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);

  Widget _buildTeacherReportCard(WeeklyReport r, JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.tintTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandBlue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.report, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              const Text(
                'تقرير المعلم (مرجع)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('التقدّم', '${r.progressPercentage.round()}%'),
              _miniStat('الدروس', '${r.lessonsCompleted}/${r.lessonsTotal}'),
              _miniStat('الواجبات',
                  '${r.homeworkSubmitted}/${r.homeworkAssigned}'),
            ],
          ),
          if (r.teacherNotes != null && r.teacherNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'ملاحظات المعلم:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(r.teacherNotes!,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildNoReportCard(JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.tintOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.info, color: AppColors.orangeDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'لم يكتب المعلم تقريراً لهذا الأسبوع بعد.\nيمكنك كتابة تقييمك بشكل مستقل.',
              style: TextStyle(fontSize: 13, color: c.onTint, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}