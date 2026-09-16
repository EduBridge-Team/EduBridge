// screens/specialist/plan_evaluation_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class PlanEvaluationScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int planId;

  const PlanEvaluationScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.planId,
  });

  @override
  State<PlanEvaluationScreen> createState() => _PlanEvaluationScreenState();
}

class _PlanEvaluationScreenState extends State<PlanEvaluationScreen> {
  bool _isAppropriate = true;
  final _notesCtrl = TextEditingController();
  final _changesCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final changes = _changesCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final ok = await ApiService.evaluatePlanAppropriateness(
        childId: widget.childId,
        planId: widget.planId,
        isAppropriate: _isAppropriate,
        notesForTeacher: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        recommendedChanges: changes.isEmpty ? null : changes,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التقييم'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'تقييم الخطة — ${widget.childName}'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  'هل الخطة مناسبة لتقدّم الطفل؟',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('✅ مناسبة'),
                        value: true,
                        groupValue: _isAppropriate,
                        onChanged: (v) =>
                            setState(() => _isAppropriate = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('❌ تحتاج تعديل'),
                        value: false,
                        groupValue: _isAppropriate,
                        onChanged: (v) =>
                            setState(() => _isAppropriate = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظاتك للمعلم',
              alignLabelWithHint: true,
              hintText: 'اكتب ملاحظاتك حول ما يحتاج تحسين...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _changesCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'التغييرات المقترحة',
              alignLabelWithHint: true,
              hintText: 'كل سطر = تغيير واحد',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isAppropriate ? AppColors.green : AppColors.orange,
              ),
              icon: Icon(_isAppropriate ? Icons.check : Icons.warning),
              label: Text(_saving ? 'جارِ الحفظ...' : 'حفظ التقييم'),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}