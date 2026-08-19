// لوحة المختص — متابعة الخطط العلاجية + إضافة دروس مع فيديو/صوت
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/tts_text.dart';
import '../widgets/tts_toggle_button.dart';
import 'child_progress_screen.dart';
import 'welcome_screen.dart';

class SpecialistDashboardScreen extends StatefulWidget {
  const SpecialistDashboardScreen({super.key});

  @override
  State<SpecialistDashboardScreen> createState() =>
      _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends State<SpecialistDashboardScreen> {
  int _tabIndex = 0;

  List<Map<String, dynamic>> _rows = [];
  List _lessons = [];
  List _types = [];
  bool _loading = true;
  String? _error;
  int? _approvingId;
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

  bool _isToday(String? ts) {
    if (ts == null || ts.isEmpty) return false;
    final d = DateTime.tryParse(ts.replaceFirst(' ', 'T'));
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Map<String, dynamic> _computeStats(List progress) {
    final total = progress.length;
    final done =
        progress.where((r) => r['status'] == 'done').length;
    final inProgress =
        progress.where((r) => r['status'] == 'in_progress').length;
    final doneToday = progress
        .where((r) =>
            r['status'] == 'done' && _isToday(r['completed_at']?.toString()))
        .length;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;
    final current = progress.cast<Map?>().firstWhere(
          (r) => r?['status'] == 'in_progress',
          orElse: () => null,
        );
    return {
      'total': total,
      'done': done,
      'inProgress': inProgress,
      'doneToday': doneToday,
      'pct': pct,
      'current': current,
    };
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

      if (responses[0].statusCode != 200) {
        setState(() {
          _error = childrenData['error'] ?? 'تعذّر جلب البيانات';
          _loading = false;
        });
        return;
      }

      final children = (childrenData['children'] ?? []) as List;
      final rows = <Map<String, dynamic>>[];

      for (final child in children) {
        final pRes =
            await ApiService.authGet('/progress/child/${child['id']}');
        final pData = jsonDecode(pRes.body);
        final progress =
            pRes.statusCode == 200 ? (pData['progress'] ?? []) : [];
        rows.add({
          'child': child,
          'progress': progress,
          'stats': _computeStats(progress),
        });
      }

      setState(() {
        _rows = rows;
        _lessons = lessonsData['lessons'] ?? [];
        _types = typesData['disability_types'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final current = row['stats']['current'];
    if (current == null) return;

    final childId = row['child']['id'];
    setState(() => _approvingId = childId);

    try {
      final res = await ApiService.authPost('/progress', {
        'child_id': childId,
        'lesson_id': current['lesson_id'],
        'status': 'done',
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _load();
      } else {
        final data = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'فشل الاعتماد')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    } finally {
      if (mounted) setState(() => _approvingId = null);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  int get _totalChildren => _rows.length;
  int get _doneToday =>
      _rows.fold(0, (s, r) => s + (r['stats']['doneToday'] as int));
  int get _pending =>
      _rows.fold(0, (s, r) => s + (r['stats']['inProgress'] as int));

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
                              ? _buildProgressTab(c)
                              : _buildLessonsTab(c),
                ),
              ),
            ],
          ),
          if (_adding) _buildAddModal(c),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'التقدّم',
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
                  const Spacer(),
                  const TtsToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'خروج',
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const TtsText(
                '🩺 لوحة المختص — متابعة وتقييم الخطط العلاجية',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              FutureBuilder<String?>(
                future: ApiService.getName(),
                builder: (context, snap) {
                  final name = snap.data ?? 'المختص';
                  return TtsText(
                    'مرحباً $name، إليك نظرة عامة على تقدّم الأطفال والخطط العلاجية',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
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
              TtsText(_error!,
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

  Widget _buildProgressTab(JisrColors c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقات المؤشرات
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: '⏳',
                value: '$_pending',
                label: 'مهام قيد الانتظار',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: '✅',
                value: '$_doneToday',
                label: 'مهام منجزة (اليوم)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: '👪',
                value: '$_totalChildren',
                label: 'إجمالي الأطفال',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TtsText(
          'جميع الأطفال والتقدّم',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: c.heading,
          ),
        ),
        const SizedBox(height: 12),
        if (_rows.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: TtsText('لا يوجد أطفال بعد',
                  style: TextStyle(fontSize: 17, color: c.muted)),
            ),
          )
        else
          ..._rows.map((row) => _buildProgressRow(row, c)),
      ],
    );
  }

  Widget _buildLessonsTab(JisrColors c) {
    if (_lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.menu_book, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد دروس بعد',
              style: TextStyle(fontSize: 18, color: c.muted),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _lessons.length,
      itemBuilder: (context, i) =>
          _buildLessonCard(_lessons[i], c),
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.heading,
          ),
        ),
        subtitle: tag != null
            ? Text(tag, style: const TextStyle(fontSize: 13))
            : null,
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }

  String? _typeName(int? id) {
    if (id == null) return null;
    for (final t in _types) {
      if (t['id'] == id) return (t['name'] ?? '').toString();
    }
    return null;
  }

  Widget _buildProgressRow(Map<String, dynamic> row, JisrColors c) {
    final child = row['child'];
    final stats = row['stats'] as Map<String, dynamic>;
    final current = stats['current'];
    final name = (child['name'] ?? '').toString();
    final need = (child['disability_name'] ?? '').toString();
    final childId = child['id'];
    final approving = _approvingId == childId;
    final color = AppColors.kidPalette[
        _rows.indexOf(row) % AppColors.kidPalette.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '🧒',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildProgressScreen(
                            childId: childId,
                            childName: name,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TtsText(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                        if (need.isNotEmpty)
                          TtsText(
                            'احتياج: $need',
                            style: TextStyle(fontSize: 13, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                ),
                TtsText(
                  '${stats['pct']}% ⭐',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (current != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.tintOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TtsText(
                      '🕒 ${current['lesson_title'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                  ),
                if ((stats['inProgress'] as int) > 0)
                  _CountBadge(
                    '${stats['inProgress']}',
                    color: AppColors.orange,
                  ),
                if ((stats['done'] as int) > 0)
                  _CountBadge(
                    '${stats['done']} ✅',
                    color: AppColors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: current != null
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                      icon: const Icon(Icons.check, size: 22),
                      label: Text(
                        approving ? 'جارٍ...' : '✔ اعتماد كمنجز',
                        style: const TextStyle(fontSize: 15),
                      ),
                      onPressed:
                          approving ? null : () => _approve(row),
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.hourglass_empty, size: 20),
                      label: const Text('⏳ بانتظار البدء'),
                      onPressed: null,
                    ),
            ),
          ],
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

class _SummaryCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            TtsText(
              '$icon $value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TtsText(
              label,
              style: TextStyle(fontSize: 11, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _CountBadge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TtsText(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}