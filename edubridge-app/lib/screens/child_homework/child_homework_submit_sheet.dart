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
}
