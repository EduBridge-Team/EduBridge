// لوحة المعلّم — عرض الأطفال الموزعين عليه، الخطة التعليمية، التواصل مع المختص
import 'dart:convert';
import 'dart:io';

import 'package:edubridge_app/screens/add_certificate_sheet.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'welcome_screen.dart';
import 'chat_screen.dart';
import 'educational_plan_sheet.dart';
import 'specialist_picker_sheet.dart';
import 'support_sheet.dart';
import 'child_lessons_screen.dart';
import 'child_progress_screen.dart';

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
  int _unreadCount = 0;

  Map? _viewingLesson;
  bool _adding = false;
  bool _showOnlyMyChildren = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotificationsCount();
  }

  Future<void> _loadData() async {
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
        final allChildren = childrenData['children'] ?? [];
        final myChildren = allChildren.where((child) {
          return child['assigned_teacher_id'] == ApiService.getUserId();
        }).toList();

        setState(() {
          _children = _showOnlyMyChildren ? myChildren : allChildren;
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

  Future<void> _loadNotificationsCount() async {
    try {
      final count = await ApiService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {}
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
    ).then((_) => _loadData());
  }

  void _viewEducationalPlan(Map child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EducationalPlanSheet(child: child),
    );
  }

  void _viewChildProgress(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildProgressScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  void _viewLesson(Map lesson) {
    setState(() => _viewingLesson = lesson);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => _loadNotificationsCount());
  }

  void _openChatWithSpecialist(Map child) async {
    try {
      final specialists = await ApiService.getSpecialists();
      if (specialists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد مختصون متاحون للتواصل')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => SpecialistPickerSheet(
          specialists: specialists,
          childName: child['name'] ?? '',
          onSelect: (specialist) {
            Navigator.pop(context);
            _openConversation(specialist, child);
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحميل المختصين: $e')),
      );
    }
  }

  Future<void> _openConversation(Map specialist, Map child) async {
    try {
      final conversationId = await ApiService.createConversation(
        specialist['id'],
        'مناقشة حالة ${child['name']}',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserName: specialist['name'] ?? '',
            otherUserRole: 'مختص',
            childName: child['name'] ?? '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إنشاء المحادثة: $e')),
      );
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'evaluated':
        return 'تم التقييم ✓';
      case 'assigned':
        return 'تم التعيين ✓';
      default:
        return 'قيد الانتظار ⏳';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'evaluated':
        return AppColors.green;
      case 'assigned':
        return AppColors.teal;
      default:
        return AppColors.orange;
    }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_tabIndex == 0)
                      Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          const SizedBox(width: 4),
                          Switch(
                            value: _showOnlyMyChildren,
                            onChanged: (val) {
                              setState(() {
                                _showOnlyMyChildren = val;
                              });
                              _loadData();
                            },
                            activeColor: AppColors.teal,
                          ),
                          Text(
                            _showOnlyMyChildren ? 'أطفالي فقط' : 'جميع الأطفال',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: _openNotifications,
                          tooltip: 'الإشعارات',
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
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
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _adding = true),
              icon: const Icon(Icons.add),
              label: const Text('إضافة درس'),
              backgroundColor: AppColors.green,
            )
          : null,
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
                    child: Text(
                      'جسر التعليمي - المعلم',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.headset_mic, color: Colors.white),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SupportSheet(),
                    ),
                    
                  ),
                  IconButton(
               icon: const Icon(Icons.workspace_premium, color: Colors.white),
              tooltip: 'إضافة شهادة',
               onPressed: () => showModalBottomSheet(
               context: context,
            isScrollControlled: true,
              backgroundColor: Colors.transparent,
                 builder: (_) => AddCertificateSheet(
                onSaved: _loadData,
    ),
  ),
),
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
                  final name = snap.data ?? 'المعلم';
                  final childCount = _children.where((c) =>
                      c['assigned_teacher_id'] == ApiService.getUserId()).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً $name 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _tabIndex == 0
                            ? 'لديك $childCount طفل${childCount != 1 ? 'اً' : ''} تحت مسؤوليتك'
                            : 'أضف دروساً جديدة أو صفّح الدروس الموجودة',
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
                  onPressed: _loadData,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenTab(JisrColors c) {
    final displayChildren = _showOnlyMyChildren
        ? _children.where((c) => c['assigned_teacher_id'] == ApiService.getUserId()).toList()
        : _children;

    if (displayChildren.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.people_outline, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _showOnlyMyChildren
                  ? 'لا يوجد أطفال موزعين عليك حالياً'
                  : 'لا يوجد أطفال مسجلون في النظام',
              style: TextStyle(fontSize: 18, color: c.muted),
            ),
          ),
          if (_showOnlyMyChildren) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'سيظهر الأطفال هنا عندما يقوم المختص بتعيينهم لك',
                style: TextStyle(fontSize: 14, color: c.muted),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: displayChildren.length,
      itemBuilder: (context, i) {
        final child = displayChildren[i];
        final color = AppColors.kidPalette[i % AppColors.kidPalette.length];
        final name = (child['name'] ?? '').toString();
        final status = child['status'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (child['disability_type'] != null)
                      Text(
                        'الإعاقة: ${child['disability_type']}',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    if (child['age'] != null)
                      Text(
                        'العمر: ${child['age']} سنة',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _openChild(child),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.school, size: 16),
                        label: const Text('الخطة'),
                        onPressed: () => _viewEducationalPlan(child),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.insights, size: 16),
                        label: const Text('التقدّم'),
                        onPressed: () => _viewChildProgress(child),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('تواصل'),
                        onPressed: () => _openChatWithSpecialist(child),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
              hintText: 'ابحث عن درس...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(Icons.menu_book, size: 72, color: c.muted),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _lessons.isEmpty ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة لبحثك',
                        style: TextStyle(fontSize: 18, color: c.muted),
                      ),
                    ),
                    if (_lessons.isEmpty)
                      const SizedBox(height: 8),
                    if (_lessons.isEmpty)
                      Center(
                        child: Text(
                          'أضف درساً جديداً باستخدام زر +',
                          style: TextStyle(fontSize: 14, color: c.muted),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.heading,
          ),
        ),
        subtitle: tag != null
            ? Text(tag, style: const TextStyle(fontSize: 12))
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
    final videoUrl = lesson['video_url'];
    final audioUrl = lesson['audio_url'];

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _viewingLesson = null),
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
              ),
              constraints: const BoxConstraints(maxHeight: 600),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                          onPressed: () => setState(() => _viewingLesson = null),
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
                        child: Text(
                          tag,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.greenDeep),
                        ),
                      ),
                    if (content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: c.body,
                          ),
                        ),
                      ),
                    if (videoUrl != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.tintTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.video_library, color: AppColors.tealDeep),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '📹 فيديو مرفق',
                                style: TextStyle(color: c.onTint),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow, size: 28),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('سيتم تشغيل الفيديو قريباً'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (audioUrl != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.tintGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.audio_file, color: AppColors.greenDeep),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🎵 تسجيل صوتي مرفق',
                                style: TextStyle(color: c.onTint),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow, size: 28),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('سيتم تشغيل التسجيل قريباً'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الدرس بنجاح 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

// ================== مكوّن إضافة الدرس ==================
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
      final result = await ApiService.createLessonWithMedia(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        disabilityTypeId: _typeId != null ? int.parse(_typeId!) : null,
        videoFile: _videoFile,
        audioFile: _audioFile,
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'نوع الإعاقة المستهدَف',
                      prefixIcon: Icon(Icons.medical_services),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.tintTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.tintGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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

// ===== شاشة الإشعارات =====
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل الإشعارات';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);
      setState(() {
        _notifications = _notifications.map((n) {
          if (n['id'] == id) {
            n['is_read'] = true;
          }
          return n;
        }).toList();
      });
    } catch (_) {}
  }

  String _getIcon(String type) {
    switch (type) {
      case 'child_added':
        return '👶';
      case 'child_evaluated':
        return '📋';
      case 'child_assigned':
        return '👨‍🏫';
      case 'lesson_added':
        return '📚';
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: 'الإشعارات',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          TextButton(
            onPressed: () async {
              await ApiService.markAllNotificationsRead();
              _loadNotifications();
            },
            child: const Text('تحديد الكل كمقروء'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: c.muted),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد إشعارات',
                            style: TextStyle(fontSize: 18, color: c.muted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notifications.length,
                      itemBuilder: (context, i) {
                        final n = _notifications[i];
                        final isRead = n['is_read'] ?? false;
                        final date = n['created_at'] != null
                            ? DateTime.parse(n['created_at'])
                            : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isRead ? null : c.tintTeal.withValues(alpha: 0.3),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Text(
                              _getIcon(n['type'] ?? ''),
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(
                              n['title'] ?? '',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: c.heading,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['body'] ?? '',
                                  style: TextStyle(color: c.body),
                                ),
                                if (date != null)
                                  Text(
                                    '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.muted,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isRead
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () => _markRead(n['id']),
                          ),
                        );
                      },
                    ),
    );
  }
}