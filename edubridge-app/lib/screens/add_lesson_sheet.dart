// lib/widgets/shared/add_lesson_sheet.dart
// نموذج إضافة درس — مُوحَّد للمعلم والمختص
// ✅ يدعم الفيديو + الترجمة + لغة الإشارة + الوصف الصوتي + دروس لأولياء الأمور
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/navigation.dart';

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

  // ✅ جديد: هل هذا الدرس موجّه لأولياء الأمور؟
  bool _forParents = false;

  final ImagePicker _picker = ImagePicker();

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
    } catch (_) {
    } finally {
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
    if (path != null && mounted) {
      setState(() => _audioFile = File(path));
    }
  }

  Future<void> _pickCaption() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['vtt', 'srt'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) {
      setState(() => _captionFile = File(path));
    }
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
      // ✅ إذا كان لأولياء الأمور، نرسل target_type = parents
      // وإلا نرسل القيمة العادية
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '➕ إضافة درس جديد',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الدرس *',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'المحتوى النصي',
                      hintText: 'اكتب محتوى الدرس (اختياري)...',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════
                  //  ✅ جديد: Switch دروس لأولياء الأمور
                  // ═══════════════════════════════════════════
                  Container(
                    decoration: BoxDecoration(
                      color: _forParents
                          ? AppColors.purple.withValues(alpha: 0.1)
                          : c.tintTeal,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _forParents ? AppColors.purple : c.line,
                        width: _forParents ? 2 : 1.5,
                      ),
                    ),
                    child: SwitchListTile(
                      value: _forParents,
                      activeThumbColor: AppColors.purple,
                      onChanged: (v) => setState(() => _forParents = v),
                      title: Row(
                        children: [
                          const Icon(Icons.family_restroom,
                              color: AppColors.purple, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'درس مخصص لأولياء الأمور',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: c.heading,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 30),
                        child: Text(
                          _forParents
                              ? '✅ سيظهر في شاشة "دروس لولي الأمر" فقط'
                              : 'فعّل هذا إذا كان الدرس موجّهاً للأسرة (كيفية التعامل مع الطفل)',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.muted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ═══ من سيستفيد (يظهر فقط إذا ليس لأولياء الأمور) ═══
                  if (!_forParents) ...[
                    _targetSelector(c),
                    const SizedBox(height: 16),
                  ],

                  // ═══ صور الدرس ═══
                  _imagesPicker(c),
                  const SizedBox(height: 12),

                  // ═══ فيديو الدرس ═══
                  _filePicker(
                    c: c,
                    icon: Icons.video_library,
                    label: '🎬 فيديو الدرس (اختياري)',
                    sublabel: 'ارفع شرحاً مرئياً للدرس',
                    color: AppColors.teal,
                    file: _videoFile,
                    onPick: _pickVideo,
                    onClear: () => setState(() => _videoFile = null),
                  ),
                  const SizedBox(height: 12),

                  // ═══ ملف الترجمة ═══
                  _filePicker(
                    c: c,
                    icon: Icons.closed_caption,
                    label: '📝 ملف ترجمات (اختياري)',
                    sublabel: 'ملف .vtt أو .srt — للصمّ وضعاف السمع',
                    color: AppColors.pink,
                    file: _captionFile,
                    onPick: _pickCaption,
                    onClear: () => setState(() => _captionFile = null),
                  ),
                  const SizedBox(height: 12),

                  // ═══ فيديو لغة الإشارة ═══
                  _filePicker(
                    c: c,
                    icon: Icons.sign_language,
                    label: '🤟 فيديو لغة الإشارة (اختياري)',
                    sublabel: 'فيديو المترجم — للصمّ',
                    color: AppColors.purple,
                    file: _signLanguageFile,
                    onPick: _pickSignLanguage,
                    onClear: () => setState(() => _signLanguageFile = null),
                  ),
                  const SizedBox(height: 12),

                  // ═══ الوصف الصوتي ═══
                  TextField(
                    controller: _audioDescriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '🔊 الوصف الصوتي (اختياري)',
                      hintText:
                          'وصف ما يحدث في الفيديو — للكفيف (يُقرأ صوتياً)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.record_voice_over),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ═══ تسجيل صوتي ═══
                  _filePicker(
                    c: c,
                    icon: Icons.audiotrack,
                    label: '🎙️ تسجيل صوتي (اختياري)',
                    sublabel: 'بديل عن الفيديو',
                    color: AppColors.green,
                    file: _audioFile,
                    onPick: _pickAudio,
                    onClear: () => setState(() => _audioFile = null),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _forParents
                                ? AppColors.purple
                                : AppColors.green,
                          ),
                          onPressed: _saving ? null : _save,
                          child: Text(
                            _saving ? 'جارِ الحفظ...' : 'حفظ الدرس',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══ اختيار الجمهور (يظهر فقط إذا لم يكن لأولياء الأمور) ═══
  Widget _targetSelector(JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tintTeal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppColors.tealDeep, size: 24),
              const SizedBox(width: 8),
              Text(
                'من سيستفيد من الدرس؟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.onTint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RadioListTile<LessonTarget>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('كل الطلاب'),
            value: LessonTarget.everyone,
            groupValue: _target,
            onChanged: (v) => setState(() => _target = v!),
          ),
          RadioListTile<LessonTarget>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('حسب نوع الإعاقة'),
            value: LessonTarget.byDisability,
            groupValue: _target,
            onChanged: (v) => setState(() => _target = v!),
          ),
          RadioListTile<LessonTarget>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('طلاب محدّدون'),
            value: LessonTarget.specificChildren,
            groupValue: _target,
            onChanged: (v) => setState(() => _target = v!),
          ),
          if (_target == LessonTarget.byDisability) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _typeId,
              decoration: const InputDecoration(
                labelText: 'نوع الإعاقة',
                filled: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— عام —')),
                ...widget.types.map((t) => DropdownMenuItem(
                      value: t['id'].toString(),
                      child: Text((t['name'] ?? '').toString()),
                    )),
              ],
              onChanged: (v) => setState(() => _typeId = v),
            ),
          ],
          if (_target == LessonTarget.specificChildren) ...[
            const SizedBox(height: 12),
            if (_loadingChildren)
              const Center(child: CircularProgressIndicator())
            else if (_allChildren.isEmpty)
              const Text('لا يوجد طلاب مسجّلون')
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allChildren.length,
                  itemBuilder: (context, i) {
                    final child = _allChildren[i];
                    final id = child['id'] as int;
                    final selected = _selectedChildIds.contains(id);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(child['name']?.toString() ?? ''),
                      subtitle: Text(
                        child['disability_type']?.toString() ?? 'غير محدد',
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedChildIds.add(id);
                          } else {
                            _selectedChildIds.remove(id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _imagesPicker(JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library,
                  color: AppColors.orange, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '🖼️ صور الدرس (اختياري)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.onTint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'يمكن اختيار عدة صور ودمجها مع الفيديو أو الصوت',
            style: TextStyle(fontSize: 11, color: c.muted),
          ),
          const SizedBox(height: 8),
          if (_imageFiles.isNotEmpty) ...[
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imageFiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final file = _imageFiles[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          file,
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 3,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _imageFiles.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 15),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: Text(
                  _imageFiles.isEmpty ? 'اختر صوراً' : 'تغيير الصور'),
              onPressed: _pickImages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filePicker({
    required JisrColors c,
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required File? file,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.onTint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sublabel, style: TextStyle(fontSize: 11, color: c.muted)),
          const SizedBox(height: 8),
          if (file == null)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('اختر ملف'),
                onPressed: onPick,
              ),
            )
          else
            Row(
              children: [
                Icon(Icons.check_circle, color: c.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.onTint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: c.onTint, size: 18),
                  onPressed: onClear,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
        ],
      ),
    );
  }
}