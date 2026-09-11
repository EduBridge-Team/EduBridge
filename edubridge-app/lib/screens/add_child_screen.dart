// شاشة إضافة طفل جديد - ولي الأمر (مع رفع هوية الطفل وشهادة الميلاد)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // ✅ ملفات مطلوبة
  File? _idCardFile;           // هوية الطفل
  File? _birthCertFile;        // شهادة الميلاد
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _disabilityTypeCtrl.dispose();
    _disabilityDescCtrl.dispose();
    _medicalHistoryCtrl.dispose();
    _psychologistNotesCtrl.dispose();
    _specialNeedsCtrl.dispose();
    _learningStyleCtrl.dispose();
    _strengthsCtrl.dispose();
    _challengesCtrl.dispose();
    super.dispose();
  }

  // اختيار صورة/ملف الهوية
  Future<void> _pickIdCard() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _idCardFile = File(picked.path));
    }
  }

  // اختيار صورة/ملف شهادة الميلاد
  Future<void> _pickBirthCert() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _birthCertFile = File(picked.path));
    }
  }

  // التقاط مباشر بالكاميرا (اختياري للهوية)
  Future<void> _captureIdCard() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _idCardFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ تحقق أن الملفات المطلوبة مرفوعة
    if (_idCardFile == null) {
      setState(() => _error = 'صورة هوية الطفل مطلوبة');
      return;
    }
    if (_birthCertFile == null) {
      setState(() => _error = 'صورة شهادة الميلاد مطلوبة');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final strengths = _strengthsCtrl.text.trim().isNotEmpty
          ? _strengthsCtrl.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : null;

      final challenges = _challengesCtrl.text.trim().isNotEmpty
          ? _challengesCtrl.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : null;

      await ApiService.addChild(
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        disabilityType: _disabilityTypeCtrl.text.trim().isEmpty
            ? null
            : _disabilityTypeCtrl.text.trim(),
        disabilityDescription: _disabilityDescCtrl.text.trim().isEmpty
            ? null
            : _disabilityDescCtrl.text.trim(),
        medicalHistory: _medicalHistoryCtrl.text.trim().isEmpty
            ? null
            : _medicalHistoryCtrl.text.trim(),
        psychologistNotes: _psychologistNotesCtrl.text.trim().isEmpty
            ? null
            : _psychologistNotesCtrl.text.trim(),
        specialNeeds: _specialNeedsCtrl.text.trim().isEmpty
            ? null
            : _specialNeedsCtrl.text.trim(),
        preferredLearningStyle: _learningStyleCtrl.text.trim().isEmpty
            ? null
            : _learningStyleCtrl.text.trim(),
        strengths: strengths,
        challenges: challenges,
        idCardFile: _idCardFile,           // ✅ جديد
        birthCertFile: _birthCertFile,     // ✅ جديد
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال بيانات الطفل بنجاح 🎉\nبانتظار مراجعة الإدارة'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
              Center(
                child: Container(
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
              ),
              const SizedBox(height: 20),

              // ✅ تنبيه المستندات المطلوبة
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.tintOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.orangeDeep),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مطلوب رفع صورة هوية الطفل وشهادة الميلاد لإتمام التسجيل.',
                        style: TextStyle(
                          color: c.onTint,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
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
                  if (int.tryParse(v.trim()) == null) {
                    return 'أدخل عمراً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ═══════════════════════════════════════════
              //  ✅ قسم المستندات الرسمية (هوية + شهادة ميلاد)
              // ═══════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_special,
                            color: AppColors.orange, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'المستندات الرسمية',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'مطلوب',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ─── هوية الطفل ───
                    _buildFilePicker(
                      context: context,
                      label: 'هوية الطفل',
                      sublabel: 'صورة واضحة للوجه الأمامي للهوية',
                      icon: Icons.credit_card,
                      file: _idCardFile,
                      onPick: _pickIdCard,
                      onCapture: _captureIdCard,
                      onRemove: () => setState(() => _idCardFile = null),
                      color: AppColors.teal,
                    ),

                    const SizedBox(height: 12),

                    // ─── شهادة الميلاد ───
                    _buildFilePicker(
                      context: context,
                      label: 'شهادة الميلاد',
                      sublabel: 'صورة واضحة للشهادة كاملة',
                      icon: Icons.card_membership,
                      file: _birthCertFile,
                      onPick: _pickBirthCert,
                      onRemove: () => setState(() => _birthCertFile = null),
                      color: AppColors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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

              // ملاحظات المختص النفسي
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
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
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
                          'إرسال للمراجعة',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ✅ ودجت موحّد لاختيار ملف (صورة/كاميرا)
  // ═══════════════════════════════════════════════════════════
  Widget _buildFilePicker({
    required BuildContext context,
    required String label,
    required String sublabel,
    required IconData icon,
    required File? file,
    required VoidCallback onPick,
    VoidCallback? onCapture,
    required VoidCallback onRemove,
    required Color color,
  }) {
    final c = JisrColors.of(context);
    final hasFile = file != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasFile
            ? color.withValues(alpha: 0.08)
            : c.tintTeal.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFile ? color : c.line,
          width: hasFile ? 2 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان + أيقونة
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ),
              if (hasFile)
                Icon(Icons.check_circle, color: c.success, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          const SizedBox(height: 10),

          // المحتوى
          if (!hasFile)
            Row(
              children: [
                // زر المعرض
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('من المعرض',
                          style: TextStyle(fontSize: 13)),
                      onPressed: onPick,
                    ),
                  ),
                ),
                if (onCapture != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('الكاميرا',
                            style: TextStyle(fontSize: 13)),
                        onPressed: onCapture,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                // معاينة مصغّرة
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: c.line,
                      child: Icon(Icons.image, color: c.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.onTint,
                        ),
                      ),
                      Text(
                        'تم الرفع',
                        style: TextStyle(fontSize: 11, color: c.success),
                      ),
                    ],
                  ),
                ),
                // زر تغيير
                IconButton(
                  icon: Icon(Icons.refresh, color: color, size: 20),
                  tooltip: 'تغيير',
                  onPressed: onPick,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                // زر حذف
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  tooltip: 'حذف',
                  onPressed: onRemove,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}