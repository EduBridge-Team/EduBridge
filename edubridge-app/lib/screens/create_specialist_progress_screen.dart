// lib/screens/create_specialist_progress_screen.dart
import 'package:flutter/material.dart';
import '../model/weekly_report_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
            content: Text('✅ تم حفظ تقدّم الطفل'),
            backgroundColor: Colors.green,
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
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: '🧠 تقييم تقدّم ${widget.childName}'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── تقرير المعلم (مرجع) ───
            if (_loadingReport)
              const Center(child: CircularProgressIndicator())
            else if (_teacherReport != null)
              _buildTeacherReportCard(_teacherReport!, c)
            else
              _buildNoReportCard(c),

            const SizedBox(height: 20),

            // ─── الملاحظات ───
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظاتك على تقدّم الطفل',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
                hintText: 'كيف ترى تقدّم الطفل من واقع تقرير المعلم؟',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // ─── التوصيات ───
            TextFormField(
              controller: _recommendationsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'توصياتك للمعلم',
                prefixIcon: Icon(Icons.lightbulb),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // ─── هل الخطة مناسبة؟ ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'هل الخطة التعليمية مناسبة لتقدّم الطفل؟',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('✅ مناسبة'),
                          value: true,
                          groupValue: _planAppropriate,
                          onChanged: (v) =>
                              setState(() => _planAppropriate = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('⚠️ تحتاج تعديل'),
                          value: false,
                          groupValue: _planAppropriate,
                          onChanged: (v) =>
                              setState(() => _planAppropriate = v!),
                        ),
                      ),
                    ],
                  ),
                  if (!_planAppropriate) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _planEvalCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'ما التعديلات المقترحة؟',
                        hintText: 'اشرح للمعلم ما يحتاج تغيير',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── المشاركة التعليمية ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintYellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مشاركة الطفل التعليمية هذا الأسبوع:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final rating = i + 1;
                      final emojis = ['😢', '😕', '😐', '🙂', '😄'];
                      final isSelected = _moodRating == rating;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _moodRating = rating),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.yellow.withValues(alpha: 0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.orange, width: 2)
                                : null,
                          ),
                          child: Text(
                            emojis[i],
                            style: const TextStyle(fontSize: 34),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _saving ? 'جارِ الحفظ...' : 'حفظ التقييم',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherReportCard(WeeklyReport r, JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.tintTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.tealDeep.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article, color: AppColors.tealDeep),
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
          const Icon(Icons.info_outline, color: AppColors.orangeDeep),
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
              color: AppColors.tealDeep,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}