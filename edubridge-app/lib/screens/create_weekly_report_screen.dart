// lib/screens/create_weekly_report_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CreateWeeklyReportScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const CreateWeeklyReportScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<CreateWeeklyReportScreen> createState() =>
      _CreateWeeklyReportScreenState();
}

class _CreateWeeklyReportScreenState extends State<CreateWeeklyReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─── الحقول ───
  final _lessonsCtrl = TextEditingController();
  final _teacherNotesCtrl = TextEditingController();
  final _achievementsCtrl = TextEditingController();
  final _concernsCtrl = TextEditingController();

  DateTime _weekStart = _lastMonday();
  int _progressPercent = 50;

  // ─── القوائم ───
  final List<String> _achievements = [];
  final List<String> _concerns = [];

  bool _saving = false;
  String? _error;

  static DateTime _lastMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void dispose() {
    _lessonsCtrl.dispose();
    _teacherNotesCtrl.dispose();
    _achievementsCtrl.dispose();
    _concernsCtrl.dispose();
    super.dispose();
  }

  void _addAchievement() {
    final text = _achievementsCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _achievements.add(text);
      _achievementsCtrl.clear();
    });
  }

  void _addConcern() {
    final text = _concernsCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _concerns.add(text);
      _concernsCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.authPost('/reports/weekly', {
        'child_id': widget.childId,
        'week_start': _weekStart.toIso8601String(),
        'lessons_completed': int.tryParse(_lessonsCtrl.text) ?? 0,
        'progress_percentage': _progressPercent,
        'teacher_notes': _teacherNotesCtrl.text.trim(),
        'achievements': _achievements,
        'concerns': _concerns,
      });

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التقرير الأسبوعي'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['error']?.toString() ?? 'فشل الحفظ';
          _saving = false;
        });
      }
    } catch (e) {
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
      appBar: JisrAppBar(title: '📊 تقرير أسبوعي — ${widget.childName}'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── تاريخ بداية الأسبوع ───
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _weekStart,
                  firstDate: DateTime.now().subtract(const Duration(days: 60)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _weekStart = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بداية الأسبوع',
                              style: TextStyle(fontSize: 12)),
                          Text(
                            '${_weekStart.day}/${_weekStart.month}/${_weekStart.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── عدد الدروس المكتملة ───
            TextFormField(
              controller: _lessonsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الدروس المكتملة',
                prefixIcon: Icon(Icons.menu_book),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // ─── نسبة التقدّم ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up,
                          color: AppColors.tealDeep),
                      const SizedBox(width: 8),
                      const Text(
                        'نسبة تقدّم الطفل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_progressPercent%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealDeep,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _progressPercent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$_progressPercent%',
                    activeColor: AppColors.tealDeep,
                    onChanged: (v) =>
                        setState(() => _progressPercent = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── ملاحظات المعلم ───
            TextFormField(
              controller: _teacherNotesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظاتك (للأهل والمختص)',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
                hintText: 'كيف كان أداء الطفل هذا الأسبوع؟',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 20),

            // ─── الإنجازات ───
            Text(
              '🏆 الإنجازات',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _achievementsCtrl,
                    decoration: const InputDecoration(
                      hintText: 'مثال: أتقن جدول الضرب',
                      prefixIcon: Icon(Icons.star, color: AppColors.yellow),
                    ),
                    onSubmitted: (_) => _addAchievement(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.green,
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _addAchievement,
                ),
              ],
            ),
            if (_achievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _achievements.asMap().entries.map((e) {
                  return Chip(
                    label: Text(e.value),
                    backgroundColor: c.tintGreen,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () =>
                        setState(() => _achievements.removeAt(e.key)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // ─── نقاط للانتباه ───
            Text(
              '⚠️ نقاط للانتباه',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _concernsCtrl,
                    decoration: const InputDecoration(
                      hintText: 'مثال: يحتاج مراجعة الحروف',
                      prefixIcon: Icon(Icons.warning, color: AppColors.orange),
                    ),
                    onSubmitted: (_) => _addConcern(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.orange,
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _addConcern,
                ),
              ],
            ),
            if (_concerns.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _concerns.asMap().entries.map((e) {
                  return Chip(
                    label: Text(e.value),
                    backgroundColor: c.tintOrange,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () =>
                        setState(() => _concerns.removeAt(e.key)),
                  );
                }).toList(),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
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
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'جارِ الحفظ...' : 'حفظ التقرير',
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
}