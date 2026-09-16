// screens/homework/child_homework_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/accessibility_service.dart';
import '../../services/api_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
import '../model/homework_model.dart';

class ChildHomeworkScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildHomeworkScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildHomeworkScreen> createState() => _ChildHomeworkScreenState();
}

class _ChildHomeworkScreenState extends State<ChildHomeworkScreen> {
  List<Homework> _homeworks = [];
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
      final list = await ApiService.getHomeworks(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _homeworks = list
            .map((e) => Homework.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الواجبات';
        _loading = false;
      });
    }
  }

  Future<void> _submit(Homework hw) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitHomeworkSheet(
        homework: hw,
        childId: widget.childId,
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: '📝 واجبات ${widget.childName}'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: JisrColors.of(context).muted),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_homeworks.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.assignment_outlined,
              size: 80, color: JisrColors.of(context).muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد واجبات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'سيظهر هنا أي واجب يضيفه معلمك',
              style: TextStyle(
                fontSize: 14,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _homeworks.length,
      itemBuilder: (context, i) => _HomeworkCard(
        homework: _homeworks[i],
        childId: widget.childId,
        onSubmit: () => _submit(_homeworks[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  بطاقة واجب واحدة
// ═══════════════════════════════════════════════════════════
class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  final int childId;
  final VoidCallback onSubmit;

  const _HomeworkCard({
    required this.homework,
    required this.childId,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large = AccessibilityService.instance
        .profile.value.extraLargeTouchTargets;

    // ابحث عن تسليم هذا الطفل
    final submission = homework.submissions
        .cast<HomeworkSubmission?>()
        .firstWhere((s) => s?.childId == childId, orElse: () => null);

    final isSubmitted = submission != null;
    final isOverdue = homework.isOverdue && !isSubmitted;

    Color statusColor;
    String statusText;
    if (isSubmitted) {
      statusColor = AppColors.green;
      statusText = submission.isLate ? 'تم التسليم (متأخر)' : 'تم التسليم';
    } else if (isOverdue) {
      statusColor = AppColors.red;
      statusText = 'متأخر';
    } else {
      statusColor = AppColors.orange;
      statusText = 'لم يُسلَّم';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── العنوان + الحالة ───
            Row(
              children: [
                Expanded(
                  child: Text(
                    homework.title,
                    style: TextStyle(
                      fontSize: large ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: large ? 14 : 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ─── الوصف ───
            if (homework.description.isNotEmpty)
              Text(
                homework.description,
                style: TextStyle(
                  fontSize: large ? 17 : 15,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 10),

            // ─── المعلومات ───
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _infoChip(
                  Icons.calendar_today,
                  'التسليم: ${homework.dueDate.day}/${homework.dueDate.month}/${homework.dueDate.year}',
                  isOverdue ? Colors.red : c.muted,
                ),
                if (homework.subject != null)
                  _infoChip(
                    Icons.book,
                    homework.subject!,
                    AppColors.tealDeep,
                  ),
                _infoChip(
                  Icons.person,
                  homework.teacherName,
                  c.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── حالة التسليم ───
            if (isSubmitted)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.tintGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: c.success, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'سلّمت هذا الواجب',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: large ? 17 : 15,
                            color: c.onTint,
                          ),
                        ),
                      ],
                    ),
                    if (submission.textAnswer != null &&
                        submission.textAnswer!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'إجابتك: ${submission.textAnswer}',
                        style: TextStyle(
                          fontSize: large ? 15 : 13,
                          color: c.onTint,
                        ),
                      ),
                    ],
                    if (submission.grade != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.yellow, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'الدرجة: ${submission.grade}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: large ? 17 : 15,
                              color: AppColors.greenDeep,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (submission.feedback != null &&
                        submission.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💬 ملاحظة المعلم: ${submission.feedback}',
                        style: TextStyle(
                          fontSize: large ? 15 : 13,
                          color: c.onTint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: large ? 64 : 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(Icons.upload, size: large ? 28 : 24),
                  label: Text(
                    'تسليم الواجب',
                    style: TextStyle(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: onSubmit,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: color),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BottomSheet تسليم الواجب — يدعم رفع ملفات متعددة
// ═══════════════════════════════════════════════════════════
class _SubmitHomeworkSheet extends StatefulWidget {
  final Homework homework;
  final int childId;

  const _SubmitHomeworkSheet({
    required this.homework,
    required this.childId,
  });

  @override
  State<_SubmitHomeworkSheet> createState() => _SubmitHomeworkSheetState();
}

class _SubmitHomeworkSheetState extends State<_SubmitHomeworkSheet> {
  final _answerCtrl = TextEditingController();
  final List<File> _files = [];
  bool _saving = false;
  String? _error;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  /// اختيار صور متعددة من المعرض
  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;
      setState(() {
        _files.addAll(images.map((x) => File(x.path)));
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'تعذّر فتح المعرض');
    }
  }

  /// التقاط صورة بالكاميرا
  Future<void> _pickFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() {
        _files.add(File(image.path));
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'تعذّر فتح الكاميرا');
    }
  }

  /// اختيار أي ملف (PDF، صوت، ...)
  Future<void> _pickAnyFile() async {
    try {
      final file = await _picker.pickMedia();
      if (file == null) return;
      setState(() {
        _files.add(File(file.path));
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'تعذّر اختيار الملف');
    }
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic');
  }

  String _fileName(String path) {
    return path.split('/').last;
  }

  Future<void> _submit() async {
    final answerText = _answerCtrl.text.trim();

    if (answerText.isEmpty && _files.isEmpty) {
      setState(() =>
          _error = 'أضف إجابة نصية أو ملفاً واحداً على الأقل');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.submitHomework(
        homeworkId: widget.homework.id,
        childId: widget.childId,
        textAnswer: answerText.isEmpty ? null : answerText,
        files: _files.isEmpty ? null : _files,
      );

      if (!mounted) return;

      // ✅ نطق صوتي عند النجاح
      TtsService.instance.speakLine('أحسنت! تم تسليم الواجب');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large = AccessibilityService.instance
        .profile.value.extraLargeTouchTargets;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── العنوان ───
              Row(
                children: [
                  const Icon(
                    Icons.upload_file,
                    color: AppColors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تسليم: ${widget.homework.title}',
                      style: TextStyle(
                        fontSize: large ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── الإجابة النصية ───
              TextField(
                controller: _answerCtrl,
                maxLines: 4,
                style: TextStyle(fontSize: large ? 18 : 16),
                decoration: InputDecoration(
                  labelText: 'الإجابة النصية (اختياري)',
                  labelStyle: TextStyle(fontSize: large ? 17 : 15),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── قسم رفع الملفات ───
              Row(
                children: [
                  const Icon(Icons.attach_file,
                      color: AppColors.tealDeep, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'أضف صوراً أو ملفات للحل:',
                    style: TextStyle(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── زر رئيسي كبير: المعرض ───
              SizedBox(
                width: double.infinity,
                height: large ? 70 : 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    Icons.photo_library,
                    size: large ? 32 : 28,
                  ),
                  label: Text(
                    'اختر صوراً من المعرض',
                    style: TextStyle(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _pickFromGallery,
                ),
              ),
              const SizedBox(height: 8),

              // ─── زرّان صغيران: الكاميرا + ملف آخر ───
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: large ? 60 : 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          Icons.camera_alt,
                          size: large ? 26 : 22,
                        ),
                        label: Text(
                          'التقط صورة',
                          style: TextStyle(fontSize: large ? 16 : 14),
                        ),
                        onPressed: _pickFromCamera,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: large ? 60 : 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.tealDeep,
                          side: const BorderSide(
                              color: AppColors.tealDeep, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          Icons.attach_file,
                          size: large ? 26 : 22,
                        ),
                        label: Text(
                          'ملف آخر',
                          style: TextStyle(fontSize: large ? 16 : 14),
                        ),
                        onPressed: _pickAnyFile,
                      ),
                    ),
                  ),
                ],
              ),

              // ─── معاينة الملفات ───
              if (_files.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.green, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'الملفات المرفوعة (${_files.length}):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: large ? 17 : 15,
                        color: c.heading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _files.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return _FilePreview(
                      file: file,
                      isImage: _isImage(file.path),
                      fileName: _fileName(file.path),
                      onRemove: () => _removeFile(index),
                    );
                  }).toList(),
                ),
              ],

              // ─── الخطأ ───
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ─── زر الإرسال ───
              SizedBox(
                height: large ? 70 : 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.send, size: large ? 28 : 24),
                  label: Text(
                    _saving ? 'جارِ الإرسال...' : 'إرسال التسليم',
                    style: TextStyle(
                      fontSize: large ? 20 : 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _saving ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  معاينة ملف مرفوع (صورة أو ملف عام)
// ═══════════════════════════════════════════════════════════
class _FilePreview extends StatelessWidget {
  final File file;
  final bool isImage;
  final String fileName;
  final VoidCallback onRemove;

  const _FilePreview({
    required this.file,
    required this.isImage,
    required this.fileName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line, width: 2),
            color: c.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: isImage
              ? Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: c.tintTeal,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          size: 40, color: AppColors.tealDeep),
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      size: 40,
                      color: AppColors.tealDeep,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
        ),
        // زر الحذف
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel,
                color: Colors.red,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}