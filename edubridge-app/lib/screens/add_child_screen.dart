// شاشة إضافة طفل جديد - ولي الأمر
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _disabilityTypeCtrl = TextEditingController();
  final _disabilityDescCtrl = TextEditingController();
  final _medicalHistoryCtrl = TextEditingController();
  final _psychologistNotesCtrl = TextEditingController();
  final _specialNeedsCtrl = TextEditingController();
  final _learningStyleCtrl = TextEditingController();
  final _strengthsCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final strengths = _strengthsCtrl.text.trim().isNotEmpty
          ? _strengthsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : null;

      final challenges = _challengesCtrl.text.trim().isNotEmpty
          ? _challengesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : null;

      await ApiService.addChild(
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        disabilityType: _disabilityTypeCtrl.text.trim().isEmpty ? null : _disabilityTypeCtrl.text.trim(),
        disabilityDescription: _disabilityDescCtrl.text.trim().isEmpty ? null : _disabilityDescCtrl.text.trim(),
        medicalHistory: _medicalHistoryCtrl.text.trim().isEmpty ? null : _medicalHistoryCtrl.text.trim(),
        psychologistNotes: _psychologistNotesCtrl.text.trim().isEmpty ? null : _psychologistNotesCtrl.text.trim(),
        specialNeeds: _specialNeedsCtrl.text.trim().isEmpty ? null : _specialNeedsCtrl.text.trim(),
        preferredLearningStyle: _learningStyleCtrl.text.trim().isEmpty ? null : _learningStyleCtrl.text.trim(),
        strengths: strengths,
        challenges: challenges,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الطفل بنجاح 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
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

    return Scaffold(
      appBar: JisrAppBar(title: 'إضافة طفل جديد'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // أيقونة
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.child_care,
                  size: 44,
                  color: AppColors.tealDeep,
                ),
              ),
              const SizedBox(height: 20),

              // الاسم
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم الطفل *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // العمر
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'العمر *',
                  prefixIcon: Icon(Icons.cake),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'العمر مطلوب';
                  if (int.tryParse(v.trim()) == null) return 'أدخل عمراً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // نوع الإعاقة
              TextFormField(
                controller: _disabilityTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'نوع الإعاقة (اختياري)',
                  prefixIcon: Icon(Icons.medical_services),
                  hintText: 'مثال: إعاقة حركية، إعاقة سمعية، ...',
                ),
              ),
              const SizedBox(height: 16),

              // وصف الإعاقة
              TextFormField(
                controller: _disabilityDescCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'وصف الإعاقة (اختياري)',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),

              // التاريخ الطبي
              TextFormField(
                controller: _medicalHistoryCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'التاريخ الطبي (اختياري)',
                  prefixIcon: Icon(Icons.history),
                ),
              ),
              const SizedBox(height: 16),

              // ملاحظات المختص النفسي (إن وجدت)
              TextFormField(
                controller: _psychologistNotesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات المختص النفسي (اختياري)',
                  prefixIcon: Icon(Icons.psychology),
                ),
              ),
              const SizedBox(height: 16),

              // احتياجات خاصة
              TextFormField(
                controller: _specialNeedsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'احتياجات خاصة (اختياري)',
                  prefixIcon: Icon(Icons.help),
                  hintText: 'مثال: يحتاج إلى دعم إضافي في القراءة',
                ),
              ),
              const SizedBox(height: 16),

              // أسلوب التعلم المفضل
              TextFormField(
                controller: _learningStyleCtrl,
                decoration: const InputDecoration(
                  labelText: 'أسلوب التعلم المفضل (اختياري)',
                  prefixIcon: Icon(Icons.school),
                  hintText: 'مثال: بصري، سمعي، حركي',
                ),
              ),
              const SizedBox(height: 16),

              // نقاط القوة
              TextFormField(
                controller: _strengthsCtrl,
                decoration: const InputDecoration(
                  labelText: 'نقاط القوة (اختياري)',
                  prefixIcon: Icon(Icons.star),
                  hintText: 'أدخل النقاط مفصولة بفواصل، مثال: قراءة، رسم،...',
                ),
              ),
              const SizedBox(height: 16),

              // التحديات
              TextFormField(
                controller: _challengesCtrl,
                decoration: const InputDecoration(
                  labelText: 'التحديات (اختياري)',
                  prefixIcon: Icon(Icons.warning),
                  hintText: 'أدخل التحديات مفصولة بفواصل، مثال: صعوبة في الكتابة، ...',
                ),
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

              // زر الإضافة
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إضافة الطفل',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}