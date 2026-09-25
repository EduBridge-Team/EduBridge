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

  const AddLessonSheet({
    super.key,
    required this.types,
    required this.onClose,
    required this.onCreated,
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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
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
                    sublabel: 'ارفع شرحاً مرئياً للدرس',
                    color: AppColors.brandTeal,
                    file: _videoFile,
                    onPick: _pickVideo,
                    onClear: () => setState(() => _videoFile = null),
                  ),
                  const SizedBox(height: 12),
                  buildFilePicker(
                    c: c,
                    icon: AppIcons.captions,
                    label: 'ملف ترجمات (اختياري)',
                    sublabel: 'ملف .vtt أو .srt — للصمّ وضعاف السمع',
                    color: AppColors.brandTeal,
                    file: _captionFile,
                    onPick: _pickCaption,
                    onClear: () => setState(() => _captionFile = null),
                  ),
                  const SizedBox(height: 12),
                  buildFilePicker(
                    c: c,
                    icon: AppIcons.signLanguage,
                    label: 'فيديو لغة الإشارة (اختياري)',
                    sublabel: 'فيديو المترجم — للصمّ',
                    color: AppColors.brandTeal,
                    file: _signLanguageFile,
                    onPick: _pickSignLanguage,
                    onClear: () => setState(() => _signLanguageFile = null),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _audioDescriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الوصف الصوتي (اختياري)',
                      hintText: 'وصف ما يحدث في الفيديو — للكفيف',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(AppIcons.speech),
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildFilePicker(
                    c: c,
                    icon: AppIcons.audio,
                    label: 'تسجيل صوتي (اختياري)',
                    sublabel: 'بديل عن الفيديو',
                    color: AppColors.brandTeal,
                    file: _audioFile,
                    onPick: _pickAudio,
                    onClear: () => setState(() => _audioFile = null),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorBox(),
                  ],
                  const SizedBox(height: 16),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
