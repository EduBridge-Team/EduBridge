// نموذج تقييم الطفل - للمختص
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class EvaluationSheet extends StatefulWidget {
  final Map child;
  final List teachers;
  final void Function(Map) onSaved;

  const EvaluationSheet({
    super.key,
    required this.child,
    required this.teachers,
    required this.onSaved,
  });

  @override
  State<EvaluationSheet> createState() => _EvaluationSheetState();
}

class _EvaluationSheetState extends State<EvaluationSheet> {
  final _formKey = GlobalKey<FormState>();

  // التقييمات
  final _cognitiveCtrl = TextEditingController();
  final _motorCtrl = TextEditingController();
  final _emotionalCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();
  final _educationalPlanCtrl = TextEditingController();
  final _teachingMethodsCtrl = TextEditingController();

  String _evaluationType = 'initial';
  int? _selectedTeacherId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cognitiveCtrl.dispose();
    _motorCtrl.dispose();
    _emotionalCtrl.dispose();
    _socialCtrl.dispose();
    _recommendationsCtrl.dispose();
    _educationalPlanCtrl.dispose();
    _teachingMethodsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final teachingMethods = _teachingMethodsCtrl.text.trim().isNotEmpty
          ? _teachingMethodsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : ['عام'];

      final result = await ApiService.evaluateChild(
        childId: widget.child['id'],
        evaluationType: _evaluationType,
        cognitiveAssessment: _cognitiveCtrl.text.trim(),
        motorAssessment: _motorCtrl.text.trim(),
        emotionalAssessment: _emotionalCtrl.text.trim(),
        socialAssessment: _socialCtrl.text.trim(),
        recommendations: _recommendationsCtrl.text.trim(),
        assignedTeacherId: _selectedTeacherId,
        educationalPlan: _educationalPlanCtrl.text.trim(),
        teachingMethods: teachingMethods,
      );

      if (!mounted) return;

      if (result != null) {
        // تحديث بيانات الطفل
        final updatedChild = widget.child;
        updatedChild['status'] = 'evaluated';
        if (_selectedTeacherId != null) {
          updatedChild['status'] = 'assigned';
          updatedChild['assigned_teacher_id'] = _selectedTeacherId;
          final teacher = widget.teachers.firstWhere(
            (t) => t['id'] == _selectedTeacherId,
            orElse: () => {},
          );
          updatedChild['assigned_teacher_name'] = teacher['name'] ?? '';
        }
        widget.onSaved(updatedChild);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تقييم الطفل بنجاح 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final childName = widget.child['name'] ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assessment, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تقييم $childName',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // نوع التقييم
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'نوع التقييم *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  value: _evaluationType,
                  items: const [
                    DropdownMenuItem(value: 'initial', child: Text('تقييم أولي')),
                    DropdownMenuItem(value: 'follow_up', child: Text('متابعة')),
                    DropdownMenuItem(value: 'final', child: Text('تقييم نهائي')),
                  ],
                  onChanged: (v) => setState(() => _evaluationType = v ?? 'initial'),
                ),
                const SizedBox(height: 16),

                // التقييم المعرفي
                TextFormField(
                  controller: _cognitiveCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التقييم المعرفي *',
                    prefixIcon: Icon(Icons.grain),
                    hintText: 'مستوى التفكير، الانتباه، الذاكرة، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // التقييم الحركي
                TextFormField(
                  controller: _motorCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التقييم الحركي *',
                    prefixIcon: Icon(Icons.fitness_center),
                    hintText: 'المهارات الحركية الدقيقة والخشنة، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // التقييم العاطفي
                TextFormField(
                  controller: _emotionalCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التقييم العاطفي *',
                    prefixIcon: Icon(Icons.mood),
                    hintText: 'الحالة النفسية، التعامل مع المشاعر، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // التقييم الاجتماعي
                TextFormField(
                  controller: _socialCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التقييم الاجتماعي *',
                    prefixIcon: Icon(Icons.people),
                    hintText: 'التفاعل مع الآخرين، المهارات الاجتماعية، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // التوصيات
                TextFormField(
                  controller: _recommendationsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التوصيات *',
                    prefixIcon: Icon(Icons.lightbulb),
                    hintText: 'توصيات للمعلم وولي الأمر، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // الخطة التعليمية
                TextFormField(
                  controller: _educationalPlanCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الخطة التعليمية *',
                    prefixIcon: Icon(Icons.school),
                    hintText: 'الخطة الدراسية المقترحة، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // طرق التدريس
                TextFormField(
                  controller: _teachingMethodsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'طرق التدريس (اختياري)',
                    prefixIcon: Icon(Icons.functions),
                    hintText: 'أدخل الطرق مفصولة بفواصل، مثال: بصري، سمعي،...',
                  ),
                ),
                const SizedBox(height: 16),

                // تعيين معلم
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'تعيين معلم (اختياري)',
                    prefixIcon: Icon(Icons.person_add),
                  ),
                  value: _selectedTeacherId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— لا تعيين —')),
                    ...widget.teachers.map((t) => DropdownMenuItem(
                          value: t['id'],
                          child: Text('${t['name'] ?? ''} (${t['email'] ?? ''})'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedTeacherId = v),
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك تعيين معلم الآن أو لاحقاً من لوحة التحكم',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
                const SizedBox(height: 16),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('حفظ التقييم'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}