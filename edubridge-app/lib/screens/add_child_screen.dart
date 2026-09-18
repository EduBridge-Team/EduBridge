// screens/add_child_screen.dart
// شاشة إضافة طفل جديد - ولي الأمر (مع رفع هوية الطفل وشهادة الميلاد)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/disability_catalog.dart';

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
  final _medicalHistoryCtrl = TextEditingController();
  final _psychologistNotesCtrl = TextEditingController();
  final _specialNeedsCtrl = TextEditingController();
  final _learningStyleCtrl = TextEditingController();
  final _strengthsCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();

  // ✅ نوع الإعاقة المختار
  String? _selectedDisabilityType;
  final _customDisabilityCtrl = TextEditingController();

  // ملفات مطلوبة
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
    _medicalHistoryCtrl.dispose();
    _psychologistNotesCtrl.dispose();
    _specialNeedsCtrl.dispose();
    _learningStyleCtrl.dispose();
    _strengthsCtrl.dispose();
    _challengesCtrl.dispose();
    _customDisabilityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIdCard() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _idCardFile = File(picked.path));
  }

  Future<void> _pickBirthCert() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _birthCertFile = File(picked.path));
  }

  Future<void> _captureIdCard() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _idCardFile = File(picked.path));
  }

  // فتح BottomSheet لاختيار نوع الإعاقة
  Future<void> _openDisabilityPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DisabilityPickerSheet(
        currentValue: _selectedDisabilityType,
      ),
    );

    if (result != null) {
      setState(() => _selectedDisabilityType = result);
    }
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

      final finalDisabilityType = _selectedDisabilityType == 'أخرى'
          ? _customDisabilityCtrl.text.trim()
          : _selectedDisabilityType;

      await ApiService.addChild(
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        disabilityType: finalDisabilityType,
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
        idCardFile: _idCardFile,
        birthCertFile: _birthCertFile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('تم إرسال بيانات الطفل بنجاح 🎉\nبانتظار مراجعة الإدارة'),
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

              // تنبيه المستندات
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
              //  نوع الإعاقة — زر يفتح BottomSheet
              // ═══════════════════════════════════════════
              _buildDisabilitySelector(c),

              // حقل نصي عند اختيار "أخرى"
              if (_selectedDisabilityType == 'أخرى') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customDisabilityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اكتب نوع الإعاقة *',
                    prefixIcon: Icon(Icons.edit),
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

              // ═══════════════════════════════════════════
              //  المستندات الرسمية
              // ═══════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color.fromARGB(255, 38, 42, 249)
                        .withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_special,
                            color: Color.fromARGB(255, 43, 242, 242),
                            size: 26),
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
                            color: const Color.fromARGB(255, 54, 219, 244)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'مطلوب',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 54, 152, 244),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFilePicker(
                      context: context,
                      label: 'هوية ولي الأمر',
                      sublabel: 'صورة واضحة للوجه الأمامي للهوية',
                      icon: Icons.credit_card,
                      file: _idCardFile,
                      onPick: _pickIdCard,
                      onCapture: _captureIdCard,
                      onRemove: () => setState(() => _idCardFile = null),
                      color: AppColors.teal,
                    ),
                    const SizedBox(height: 12),
                    _buildFilePicker(
                      context: context,
                      label: 'شهادة الميلاد',
                      sublabel: 'صورة واضحة للشهادة كاملة',
                      icon: Icons.card_membership,
                      file: _birthCertFile,
                      onPick: _pickBirthCert,
                      onRemove: () => setState(() => _birthCertFile = null),
                      color: const Color.fromARGB(255, 43, 235, 242),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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

              // ملاحظات المختص
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
                ),
              ),
              const SizedBox(height: 16),

              // أسلوب التعلم
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
                  hintText: 'مفصولة بفواصل: قراءة، رسم،...',
                ),
              ),
              const SizedBox(height: 16),

              // التحديات
              TextFormField(
                controller: _challengesCtrl,
                decoration: const InputDecoration(
                  labelText: 'التحديات (اختياري)',
                  prefixIcon: Icon(Icons.warning),
                  hintText: 'مفصولة بفواصل',
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
                        color: Colors.red.withValues(alpha: 0.4),
                      ),
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
                              color: Colors.red,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 25, 198, 195),
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
  //  زر نوع الإعاقة
  // ═══════════════════════════════════════════════════════════
  Widget _buildDisabilitySelector(JisrColors c) {
    final hasValue = _selectedDisabilityType != null;

    return InkWell(
      onTap: _openDisabilityPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue ? AppColors.teal : c.line,
            width: hasValue ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.medical_services,
              color: hasValue ? AppColors.teal : c.muted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوع الإعاقة *',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasValue ? AppColors.teal : c.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasValue ? _selectedDisabilityType! : 'اضغط للاختيار',
                    style: TextStyle(
                      fontSize: 15,
                      color: hasValue ? c.heading : c.muted,
                      fontWeight:
                          hasValue ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: hasValue ? AppColors.teal : c.muted,
            ),
          ],
        ),
      ),
    );
  }

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
          Text(sublabel, style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 10),
          if (!hasFile)
            Row(
              children: [
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
                IconButton(
                  icon: Icon(Icons.refresh, color: color, size: 20),
                  tooltip: 'تغيير',
                  onPressed: onPick,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
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

// ═══════════════════════════════════════════════════════════
//  BottomSheet لاختيار نوع الإعاقة
// ═══════════════════════════════════════════════════════════
class _DisabilityPickerSheet extends StatefulWidget {
  final String? currentValue;

  const _DisabilityPickerSheet({this.currentValue});

  @override
  State<_DisabilityPickerSheet> createState() =>
      _DisabilityPickerSheetState();
}

class _DisabilityPickerSheetState extends State<_DisabilityPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DisabilityCategory> get _filteredCategories {
    if (_search.trim().isEmpty) return kDisabilityCategories;

    final q = _search.trim().toLowerCase();
    final result = <DisabilityCategory>[];

    for (final cat in kDisabilityCategories) {
      final matchingItems = cat.items
          .where((item) => item.toLowerCase().contains(q))
          .toList();

      if (matchingItems.isNotEmpty ||
          cat.label.toLowerCase().contains(q)) {
        result.add(DisabilityCategory(
          label: cat.label,
          emoji: cat.emoji,
          items: matchingItems.isEmpty ? cat.items : matchingItems,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final categories = _filteredCategories;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط السحب
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: c.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // العنوان
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.medical_services,
                    color: AppColors.tealDeep, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اختر نوع الإعاقة',
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
          ),

          // بحث
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث عن إعاقة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: c.tintTeal.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // القائمة
          Flexible(
            child: categories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: c.muted),
                          const SizedBox(height: 12),
                          Text('لا توجد نتائج',
                              style: TextStyle(
                                  fontSize: 16, color: c.muted)),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      // خيار "بدون تكييف" في الأعلى
                      _buildNoDisabilityOption(c),

                      const SizedBox(height: 8),

                      // الفئات
                      ...categories
                          .map((cat) => _buildCategory(cat, c)),

                      // "أخرى"
                      const SizedBox(height: 8),
                      _buildOtherOption(c),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ خيار "بدون تكييف"
  Widget _buildNoDisabilityOption(JisrColors c) {
    final isSelected = widget.currentValue == 'بدون تكييف';

    return InkWell(
      onTap: () => Navigator.pop(context, 'بدون تكييف'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal.withValues(alpha: 0.15)
              : c.tintTeal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.teal
                : c.line,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('⚪', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'بدون تكييف',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(DisabilityCategory cat, JisrColors c) {
    final hasCurrent = widget.currentValue != null &&
        cat.items.contains(widget.currentValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: ExpansionTile(
        initiallyExpanded: hasCurrent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:
            const EdgeInsets.only(bottom: 8, left: 8, right: 8),
        iconColor: AppColors.tealDeep,
        collapsedIconColor: c.muted,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(cat.emoji,
              style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          cat.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.heading,
          ),
        ),
        subtitle: Text(
          '${cat.items.length} ${cat.items.length == 1 ? 'حالة' : 'حالات'}',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        children: cat.items.map((item) {
          final isSelected = widget.currentValue == item;
          return InkWell(
            onTap: () => Navigator.pop(context, item),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              margin: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal.withValues(alpha: 0.2)
                    : c.tintTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: AppColors.teal, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.arrow_left,
                    size: 18,
                    color: AppColors.tealDeep,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: c.heading,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOtherOption(JisrColors c) {
    final isSelected = widget.currentValue == 'أخرى';

    return InkWell(
      onTap: () => Navigator.pop(context, 'أخرى'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.2)
              : AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('✏️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أخرى',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  Text(
                    'اكتب نوع الإعاقة بنفسك',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_left, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}