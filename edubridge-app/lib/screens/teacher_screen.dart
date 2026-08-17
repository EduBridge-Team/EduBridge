// لوحة المعلّم — الأطفال + البحث في الدروس + إضافة درس مع فيديو/صوت
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/tts_text.dart';
import '../widgets/tts_toggle_button.dart';
import 'child_lessons_screen.dart';
import 'welcome_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _tabIndex = 0;

  List _children = [];
  List _lessons = [];
  List _types = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  Map? _viewingLesson;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.authGet('/children'),
        ApiService.authGet('/lessons'),
        ApiService.authGet('/disability-types'),
      ]);

      final childrenData = jsonDecode(responses[0].body);
      final lessonsData = jsonDecode(responses[1].body);
      final typesData = jsonDecode(responses[2].body);

      if (responses[0].statusCode == 200 &&
          responses[1].statusCode == 200 &&
          responses[2].statusCode == 200) {
        setState(() {
          _children = childrenData['children'] ?? [];
          _lessons = lessonsData['lessons'] ?? [];
          _types = typesData['disability_types'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = childrenData['error'] ??
              lessonsData['error'] ??
              typesData['error'] ??
              'تعذّر جلب البيانات';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  String? _typeName(int? id) {
    if (id == null) return null;
    for (final t in _types) {
      if (t['id'] == id) return (t['name'] ?? '').toString();
    }
    return null;
  }

  List get _filteredLessons {
    final q = _query.trim();
    if (q.isEmpty) return _lessons;
    return _lessons.where((l) {
      final title = (l['title'] ?? '').toString();
      final content = (l['content'] ?? '').toString();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _openChild(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildLessonsScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  void _viewLesson(Map lesson) {
    setState(() => _viewingLesson = lesson);
  }

  Future<void> _toggleSpeakLesson(Map lesson) async {
    final text = [
      (lesson['title'] ?? '').toString(),
      (lesson['content'] ?? '').toString(),
    ].where((t) => t.isNotEmpty).join('. ');
    await TtsService.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(c),
              if (_tabIndex == 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text('إضافة درس جديد',
                          style: TextStyle(fontSize: 17)),
                      onPressed: () => setState(() => _adding = true),
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildError()
                          : _tabIndex == 0
                              ? _buildChildrenTab(c)
                              : _buildLessonsTab(c),
                ),
              ),
            ],
          ),
          if (_viewingLesson != null) _buildViewModal(c),
          if (_adding) _buildAddModal(c),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'الأطفال',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'الدروس',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(JisrColors c) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/icon.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TtsText(
                      'EduBridge — جسر تعليمي',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const TtsToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'خروج',
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: ApiService.getName(),
                builder: (context, snap) {
                  final name = snap.data ?? 'المعلّم';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TtsText(
                        'مرحباً $name،',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TtsText(
                        _tabIndex == 0
                            ? 'إليك الأطفال المسندة إليك مسؤوليتهم اليوم'
                            : 'أضفِ دروساً جديدة أو صفِّح الدروس الموجودة',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Text(_error!,
                  style: const TextStyle(fontSize: 16, color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 28),
                  label: const Text('إعادة المحاولة',
                      style: TextStyle(fontSize: 18)),
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenTab(JisrColors c) {
    if (_children.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.people_outline, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Center(
            child: Text('لا يوجد أطفال بعد', style: TextStyle(fontSize: 18)),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _children.length,
      itemBuilder: (context, i) {
        final child = _children[i];
        final color = AppColors.kidPalette[i % AppColors.kidPalette.length];
        final name = (child['name'] ?? '').toString();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Text(
                name.isNotEmpty ? name.characters.first : '🙂',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.heading,
              ),
            ),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _openChild(child),
          ),
        );
      },
    );
  }

  Widget _buildLessonsTab(JisrColors c) {
    final filtered = _filteredLessons;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
              hintText: 'ابحث عن درس...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    Icon(Icons.menu_book, size: 72, color: c.muted),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _lessons.isEmpty ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة لبحثك',
                        style: TextStyle(fontSize: 18, color: c.muted),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _buildLessonCard(filtered[i], c),
                ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Map lesson, JisrColors c) {
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();
    final tag = _typeName(lesson['disability_type_id']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: c.tintGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.menu_book, size: 28, color: c.success),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.heading,
          ),
        ),
        subtitle: tag != null
            ? Text(tag, style: const TextStyle(fontSize: 13))
            : null,
        trailing: const Icon(Icons.chevron_left),
        onTap: () => _viewLesson(lesson),
      ),
    );
  }

  Widget _buildViewModal(JisrColors c) {
    final lesson = _viewingLesson!;
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();
    final tag = _typeName(lesson['disability_type_id']);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          TtsService.stop();
          setState(() => _viewingLesson = null);
        },
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TtsText(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: c.heading,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            TtsService.stop();
                            setState(() => _viewingLesson = null);
                          },
                        ),
                      ],
                    ),
                    if (tag != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TtsText(tag,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.greenDeep)),
                      ),
                    TtsText(
                      content.isNotEmpty
                          ? content
                          : 'لا يوجد محتوى لهذا الدرس.',
                      style:
                          TextStyle(fontSize: 16, height: 1.5, color: c.body),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up),
                        label: const Text('استمع'),
                        onPressed: () => _toggleSpeakLesson(lesson),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddModal(JisrColors c) {
    return Positioned.fill(
      child: _AddLessonSheet(
        types: _types,
        onClose: () => setState(() => _adding = false),
        onCreated: (lesson) {
          setState(() {
            _lessons = [lesson, ..._lessons];
            _adding = false;
          });
        },
      ),
    );
  }
}

class _AddLessonSheet extends StatefulWidget {
  final List types;
  final VoidCallback onClose;
  final void Function(Map lesson) onCreated;

  const _AddLessonSheet({
    required this.types,
    required this.onClose,
    required this.onCreated,
  });

  @override
  State<_AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends State<_AddLessonSheet> {

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String? _typeId;
  File? _videoFile;
  File? _audioFile;
  bool _saving = false;
  String? _error;

 final ImagePicker _picker = ImagePicker();

Future<void> _pickVideo() async {
  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
  if (video != null) {
    setState(() => _videoFile = File(video.path));
  }
}

Future<void> _pickAudio() async {
  // للبيانات والأصوات
  final XFile? audio = await _picker.pickMedia(); 
  if (audio != null) {
    setState(() => _audioFile = File(audio.path));
  }
}

  void _removeVideo() {
    setState(() => _videoFile = null);
  }

  void _removeAudio() {
    setState(() => _audioFile = null);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'عنوان الدرس مطلوب');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.createLessonWithMedia(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        disabilityTypeId: _typeId != null ? int.parse(_typeId!) : null,
        videoFile: _videoFile,
        audioFile: _audioFile,
      );

      if (!mounted) return;

      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        widget.onCreated(data['lesson']);
      } else {
        setState(() {
          _error = data['error'] ?? 'فشل حفظ الدرس';
          _saving = false;
        });
      }
    } catch (e) {
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
                        child: TtsText(
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
                    decoration: const InputDecoration(labelText: 'عنوان الدرس *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'المحتوى النصي',
                      hintText: 'اكتب محتوى الدرس (اختياري)...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'نوع الإعاقة المستهدَف',
                    ),
                    value: _typeId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— عام (كل الأنواع) —'),
                      ),
                      ...widget.types.map((t) => DropdownMenuItem(
                            value: t['id'].toString(),
                            child: Text((t['name'] ?? '').toString()),
                          )),
                    ],
                    onChanged: (v) => setState(() => _typeId = v),
                  ),
                  const SizedBox(height: 16),

                  // ===== رفع الفيديو =====
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.tintTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TtsText(
                          '🎬 فيديو الدرس (اختياري)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: c.onTint,
                          ),
                        ),
                        if (_videoFile == null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('اختر ملف فيديو'),
                              onPressed: _pickVideo,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: c.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _videoFile!.path.split('/').last,
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
                                onPressed: _removeVideo,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== رفع الصوت =====
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.tintGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TtsText(
                          '🎙️ تسجيل صوتي (اختياري)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: c.onTint,
                          ),
                        ),
                        if (_audioFile == null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('اختر ملف صوت'),
                              onPressed: _pickAudio,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: c.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _audioFile!.path.split('/').last,
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
                                onPressed: _removeAudio,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
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
                            backgroundColor: AppColors.green,
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
}
