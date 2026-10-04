// lib/screens/add_lesson/add_lesson_sheet.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

part 'add_lesson_target_selector.dart';
part 'add_lesson_media_pickers.dart';
part 'add_lesson_widgets.dart';

enum LessonTarget { everyone, byDisability, specificChildren }

class AddLessonSheet extends StatefulWidget {
  final List types;
  final VoidCallback onClose;
  final void Function(Map lesson) onCreated;
  final bool fullScreen;
  final bool forParents;
  final int? initialChildId;
  final String? initialChildName;

  const AddLessonSheet({
    super.key,
    required this.types,
    required this.onClose,
    required this.onCreated,
    this.fullScreen = false,
    this.forParents = false,
    this.initialChildId,
    this.initialChildName,
  });

  @override
  State<AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends State<AddLessonSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _audioDescriptionCtrl = TextEditingController();

  String? _typeId;
  final List<File> _imageFiles = [];
  File? _videoFile;
  File? _audioFile;
  File? _captionFile;
  File? _signLanguageFile;

  bool _saving = false;
  String? _error;

  LessonTarget _target = LessonTarget.everyone;
  final Set<int> _selectedChildIds = {};
  List _allChildren = [];
  bool _loadingChildren = false;

  bool _forParents = false;

  final ImagePicker _picker = ImagePicker();

  void _updateLessonSheetState(VoidCallback callback) => setState(callback);

  bool get _isChildLocked => widget.initialChildId != null;

  @override
  void initState() {
    super.initState();
    _forParents = widget.forParents;
    if (widget.initialChildId != null) {
      _target = LessonTarget.specificChildren;
      _selectedChildIds.add(widget.initialChildId!);
      _forParents = false;
    }
    _loadChildren();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _audioDescriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _loadingChildren = true);
    try {
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && mounted) {
        setState(() => _allChildren = data['children'] ?? []);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingChildren = false);
    }
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 90);
    if (images.isNotEmpty && mounted) {
      setState(() {
        _imageFiles
          ..clear()
          ..addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && mounted) {
      setState(() => _videoFile = File(video.path));
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) setState(() => _audioFile = File(path));
  }

  Future<void> _pickCaption() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['vtt', 'srt'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) setState(() => _captionFile = File(path));
  }

  Future<void> _pickSignLanguage() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && mounted) {
      setState(() => _signLanguageFile = File(video.path));
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'عنوان الدرس مطلوب');
      return;
    }
    if (_target == LessonTarget.specificChildren && _selectedChildIds.isEmpty) {
      setState(() => _error = 'اختر طالباً واحداً على الأقل');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final targetType = _forParents ? 'parents' : _target.name;

      final result = await ApiService.createLessonWithMedia(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim().isEmpty
            ? null
            : _contentCtrl.text.trim(),
        disabilityTypeId: _typeId != null ? int.parse(_typeId!) : null,
        imageFiles: _imageFiles,
        videoFile: _videoFile,
        audioFile: _audioFile,
        captionFile: _captionFile,
        signLanguageFile: _signLanguageFile,
        audioDescription: _audioDescriptionCtrl.text.trim().isEmpty
            ? null
            : _audioDescriptionCtrl.text.trim(),
        targetType: targetType,
        targetChildIds: _target == LessonTarget.specificChildren
            ? _selectedChildIds.toList()
            : null,
      );

      if (!mounted) return;
      if (result != null) {
        widget.onCreated(result);
      } else {
        setState(() {
          _error = 'فشل حفظ الدرس';
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر: $e';
        _saving = false;
      });
    }
  }

  Widget _formContent(JisrColors c) {
    return SingleChildScrollView(
      padding: widget.fullScreen
          ? const EdgeInsets.fromLTRB(16, 16, 16, 128)
          : EdgeInsets.zero,
      child: Container(
        margin: widget.fullScreen
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(12, 52, 12, 12),
        padding: widget.fullScreen ? EdgeInsets.zero : const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: widget.fullScreen ? BorderRadius.zero : BorderRadius.circular(28),
          border: widget.fullScreen ? null : Border.all(color: c.line),
          boxShadow: widget.fullScreen
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .10),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (!widget.fullScreen) const SizedBox(height: 6),
            Text(
              _isChildLocked
                  ? 'هذا الدرس سيظهر للطالب ${widget.initialChildName ?? ''} فقط.'
                  : 'أضف المحتوى وحدد الجمهور والوسائط المساندة.',
              style: TextStyle(fontSize: 13.5, color: c.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'عنوان الدرس *',
                prefixIcon: Icon(AppIcons.edit),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'المحتوى النصي',
                hintText: 'اكتب محتوى الدرس (اختياري)...',
                prefixIcon: Icon(AppIcons.info),
              ),
            ),
            const SizedBox(height: 16),
            if (_isChildLocked) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: .18)),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.child, color: AppColors.brandBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الطالب: ${widget.initialChildName ?? widget.initialChildId}',
                        style: TextStyle(color: c.heading, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildForParentsToggle(c),
              const SizedBox(height: 16),
              if (!_forParents) ...[
                buildTargetSelector(
                  context: context,
                  c: c,
                  target: _target,
                  onTargetChanged: (v) => setState(() => _target = v),
                  typeId: _typeId,
                  onTypeChanged: (v) => setState(() => _typeId = v),
                  types: widget.types,
                  allChildren: _allChildren,
                  selectedChildIds: _selectedChildIds,
                  loadingChildren: _loadingChildren,
                  onChildToggle: (id, selected) => setState(() {
                    if (selected) {
                      _selectedChildIds.add(id);
                    } else {
                      _selectedChildIds.remove(id);
                    }
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ],
            buildImagesPicker(
              context: context,
              c: c,
              imageFiles: _imageFiles,
              onPick: _pickImages,
              onRemove: (i) => setState(() => _imageFiles.removeAt(i)),
            ),
            const SizedBox(height: 12),
            buildFilePicker(
              c: c,
              icon: AppIcons.video,
              label: 'فيديو الدرس (اختياري)',
              sublabel: 'أرفق فيديو يشرح محتوى الدرس',
              color: AppColors.brandTeal,
              file: _videoFile,
              onPick: _pickVideo,
              onClear: () => setState(() => _videoFile = null),
              uploadLabel: 'رفع الفيديو',
            ),
            const SizedBox(height: 12),
            buildFilePicker(
              c: c,
              icon: AppIcons.captions,
              label: 'ملف الترجمة (اختياري)',
              sublabel: 'ملف VTT أو SRT للصم وضعاف السمع',
              color: AppColors.brandTeal,
              file: _captionFile,
              onPick: _pickCaption,
              onClear: () => setState(() => _captionFile = null),
              uploadLabel: 'رفع ملف الترجمة',
            ),
            const SizedBox(height: 12),
            buildFilePicker(
              c: c,
              icon: AppIcons.signLanguage,
              label: 'فيديو لغة الإشارة (اختياري)',
              sublabel: 'أرفق فيديو مترجماً بلغة الإشارة',
              color: AppColors.brandTeal,
              file: _signLanguageFile,
              onPick: _pickSignLanguage,
              onClear: () => setState(() => _signLanguageFile = null),
              uploadLabel: 'رفع فيديو الإشارة',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _audioDescriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الوصف الصوتي (اختياري)',
                hintText: 'صف ما يحدث في الفيديو للمكفوفين وضعاف البصر',
                alignLabelWithHint: true,
                prefixIcon: Icon(AppIcons.speech),
              ),
            ),
            const SizedBox(height: 12),
            buildFilePicker(
              c: c,
              icon: AppIcons.audio,
              label: 'تسجيل صوتي (اختياري)',
              sublabel: 'أرفق تسجيلاً صوتياً بديلاً عن الفيديو',
              color: AppColors.brandTeal,
              file: _audioFile,
              onPick: _pickAudio,
              onClear: () => setState(() => _audioFile = null),
              uploadLabel: 'رفع التسجيل الصوتي',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildErrorBox(),
            ],
            if (!widget.fullScreen) ...[
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final content = GestureDetector(onTap: () {}, child: _formContent(c));
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return GestureDetector(
      onTap: widget.fullScreen ? null : widget.onClose,
      child: Container(
        color: widget.fullScreen
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.black54,
        alignment: widget.fullScreen ? Alignment.topCenter : Alignment.center,
        child: widget.fullScreen
            ? Stack(
                children: [
                  Positioned.fill(child: content),
                  Positioned(
                    left: 16,
                    bottom: 24 + bottomInset,
                    width: 220,
                    child: _buildSaveButton(),
                  ),
                ],
              )
            : content,
      ),
    );
  }
}
