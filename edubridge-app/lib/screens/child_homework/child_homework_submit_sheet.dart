// lib/screens/child_homework/child_homework_submit_sheet.dart
part of 'child_homework_screen.dart';

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
      setState(() => _error = 'أضف إجابة نصية أو ملفاً واحداً على الأقل');
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
              _buildHeader(c, large),
              const SizedBox(height: 16),
              _buildAnswerField(large),
              const SizedBox(height: 20),
              _buildAttachHeader(c, large),
              const SizedBox(height: 12),
              _buildMainAttachButton(large),
              const SizedBox(height: 8),
              _buildSecondaryAttachRow(large),
              if (_files.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFilesPreview(c, large),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                _buildErrorBox(),
              ],
              const SizedBox(height: 20),
              _buildSubmitButton(large),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(JisrColors c, bool large) {
    return Row(
      children: [
        const Icon(AppIcons.upload, color: AppColors.green, size: 32),
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
          icon: const Icon(AppIcons.close, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildAnswerField(bool large) {
    return TextField(
      controller: _answerCtrl,
      maxLines: 4,
      style: TextStyle(fontSize: large ? 18 : 16),
      decoration: InputDecoration(
        labelText: 'الإجابة النصية (اختياري)',
        labelStyle: TextStyle(fontSize: large ? 17 : 15),
        alignLabelWithHint: true,
        prefixIcon: const Icon(AppIcons.edit),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildAttachHeader(JisrColors c, bool large) {
    return Row(
      children: [
        const Icon(AppIcons.attach, color: AppColors.brandBlue, size: 22),
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
    );
  }

  Widget _buildMainAttachButton(bool large) {
    return SizedBox(
      width: double.infinity,
      height: large ? 70 : 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(AppIcons.image, size: large ? 32 : 28),
        label: Text(
          'اختر صوراً من المعرض',
          style: TextStyle(
            fontSize: large ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _pickFromGallery,
      ),
    );
  }

  Widget _buildSecondaryAttachRow(bool large) {
    return Row(
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
              icon: Icon(AppIcons.camera, size: large ? 26 : 22),
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
                foregroundColor: AppColors.brandBlue,
                side: const BorderSide(color: AppColors.brandBlue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(AppIcons.attach, size: large ? 26 : 22),
              label: Text(
                'ملف آخر',
                style: TextStyle(fontSize: large ? 16 : 14),
              ),
              onPressed: _pickAnyFile,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilesPreview(JisrColors c, bool large) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.check, color: AppColors.green, size: 22),
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
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.error, color: AppColors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool large) {
    return SizedBox(
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
            : Icon(AppIcons.send, size: large ? 28 : 24),
        label: Text(
          _saving ? 'جارِ الإرسال...' : 'إرسال التسليم',
          style: TextStyle(
            fontSize: large ? 20 : 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _saving ? null : _submit,
      ),
    );
  }
}

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
                      child: Icon(AppIcons.image,
                          size: 40, color: AppColors.brandBlue),
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      size: 40,
                      color: AppColors.brandBlue,
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
                color: AppColors.red,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}