// lib/screens/add_child/add_child_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/disability/disability_picker_sheet.dart';

part 'add_child_file_pickers.dart';
part 'add_child_disability_field.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _disabilityDescCtrl = TextEditingController();
  final _specialNeedsCtrl = TextEditingController();
  final _learningStyleCtrl = TextEditingController();
  final _strengthsCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();
  final _customDisabilityCtrl = TextEditingController();

  String? _selectedDisabilityType;
  File? _idCardFile;
  File? _birthCertFile;
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _disabilityDescCtrl.dispose();
    _specialNeedsCtrl.dispose();
    _learningStyleCtrl.dispose();
    _strengthsCtrl.dispose();
    _challengesCtrl.dispose();
    _customDisabilityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIdCard() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _idCardFile = File(picked.path));
  }

  Future<void> _pickBirthCert() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _birthCertFile = File(picked.path));
  }

  Future<void> _captureIdCard() async {
    final picked = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _idCardFile = File(picked.path));
  }

  Future<void> _openDisabilityPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DisabilityPickerSheet(
        currentValue: _selectedDisabilityType,
      ),
    );
    if (result != null) setState(() => _selectedDisabilityType = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDisabilityType == null) {
      setState(() => _error = 'يجب اختيار نوع الإعاقة');
      return;
    }
    if (_selectedDisabilityType == 'أخرى' &&
        _customDisabilityCtrl.text.trim().isEmpty) {
      setState(() => _error = 'يجب كتابة نوع الإعاقة');
      return;
    }
    if (_idCardFile == null) {
      setState(() => _error = 'صورة هوية ولي الأمر مطلوبة');
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
      final strengths = _parseCsv(_strengthsCtrl.text);
      final challenges = _parseCsv(_challengesCtrl.text);

      final finalDisabilityType = _selectedDisabilityType == 'أخرى'
          ? _customDisabilityCtrl.text.trim()
          : _selectedDisabilityType;

      await ApiService.addChild(
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        disabilityType: finalDisabilityType,
        disabilityDescription: _optional(_disabilityDescCtrl.text),
        specialNeeds: _optional(_specialNeedsCtrl.text),
        preferredLearningStyle: _optional(_learningStyleCtrl.text),
        strengths: strengths,
        challenges: challenges,
        idCardFile: _idCardFile,
        birthCertFile: _birthCertFile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال بيانات الطفل بنجاح\nبانتظار مراجعة الإدارة'),
          backgroundColor: AppColors.green,
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

  List<String>? _parseCsv(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return trimmed
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String? _optional(String text) =>
      text.trim().isEmpty ? null : text.trim();

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
              _buildAvatarHeader(c),
              const SizedBox(height: 20),
              _buildInfoBanner(c),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم الطفل *',
                  prefixIcon: Icon(AppIcons.profile),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'العمر *',
                  prefixIcon: Icon(AppIcons.calendar),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'العمر مطلوب';
                  if (int.tryParse(v.trim()) == null) return 'أدخل عمراً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              buildDisabilityField(
                context: context,
                c: c,
                selectedValue: _selectedDisabilityType,
                onTap: _openDisabilityPicker,
              ),

              if (_selectedDisabilityType == 'أخرى') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customDisabilityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اكتب نوع الإعاقة *',
                    prefixIcon: Icon(AppIcons.edit),
                    hintText: 'مثال: اضطراب المعالجة السمعية',
                  ),
                  validator: (v) {
                    if (_selectedDisabilityType != 'أخرى') return null;
                    return (v == null || v.trim().isEmpty)
                        ? 'يجب كتابة نوع الإعاقة'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              buildDocumentsSection(
                context: context,
                c: c,
                idCardFile: _idCardFile,
                birthCertFile: _birthCertFile,
                onPickId: _pickIdCard,
                onCaptureId: _captureIdCard,
                onRemoveId: () => setState(() => _idCardFile = null),
                onPickBirth: _pickBirthCert,
                onRemoveBirth: () => setState(() => _birthCertFile = null),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _disabilityDescCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '*وصف الإعاقة',
                  prefixIcon: Icon(AppIcons.info),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'وصف الإعاقة مطلوب'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specialNeedsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'احتياجات خاصة (اختياري)',
                  prefixIcon: Icon(AppIcons.info),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _learningStyleCtrl,
                decoration: const InputDecoration(
                  labelText: '*أسلوب التعلم المفضل',
                  prefixIcon: Icon(AppIcons.lesson),
                  hintText: 'مثال: بصري، سمعي، حركي',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'أسلوب التعلم مطلوب'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _strengthsCtrl,
                decoration: const InputDecoration(
                  labelText: '*نقاط القوة',
                  prefixIcon: Icon(AppIcons.starFilled),
                  hintText: 'مفصولة بفواصل: قراءة، رسم،...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'نقاط القوة مطلوبة'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _challengesCtrl,
                decoration: const InputDecoration(
                  labelText: '*التحديات',
                  prefixIcon: Icon(AppIcons.warning),
                  hintText: 'مفصولة بفواصل',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'التحديات مطلوبة' : null,
              ),
              const SizedBox(height: 16),

              if (_error != null) _buildErrorBox(_error!),

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(AppIcons.send),
                  label: Text(
                    _loading ? 'جارٍ الإرسال...' : 'إرسال للمراجعة',
                    style: const TextStyle(
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

  Widget _buildAvatarHeader(JisrColors c) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: c.tintTeal,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(AppIcons.child, size: 44, color: AppColors.brandBlue),
      ),
    );
  }

  Widget _buildInfoBanner(JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tintOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.info, color: AppColors.orangeDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'مطلوب رفع صورة هوية ولي الأمر وشهادة الميلاد لإتمام التسجيل.',
              style: TextStyle(
                color: c.onTint,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(AppIcons.error, color: AppColors.red, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error,
                  style: const TextStyle(color: AppColors.red, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}