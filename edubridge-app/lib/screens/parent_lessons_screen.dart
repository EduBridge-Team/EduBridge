// lib/screens/parent_lessons_screen.dart
// دروس مخصصة لأولياء الأمور
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import 'add_lesson/add_lesson_screen.dart';
import '../widgets/teacher_navigation_bar.dart';
import '../services/api_service.dart';
import '../services/paged_list_controller.dart';
import '../widgets/list_pagination.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/accessibility/adaptive_video_player.dart';

part 'parent_lessons_widgets.dart';

class ParentLessonsScreen extends StatefulWidget {
  const ParentLessonsScreen({super.key});

  @override
  State<ParentLessonsScreen> createState() => _ParentLessonsScreenState();
}

class _ParentLessonsScreenState extends State<ParentLessonsScreen> {
  String? _role;
  List _lessons = [];
  late final PagedListController _pages;
  bool _loading = true;
  String? _error;
  String _query = '';

  int? _speakingLessonId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeAudioUrl;

  @override
  void initState() {
    super.initState();
    _pages = PagedListController((page, query) => ApiService.getLessonsPage(page: page, query: query, targetType: 'parents'));
    _pages.addListener(_syncPage);
    ApiService.getRole().then((role) { if (mounted) setState(() => _role = role); });
    _load();
  }

  @override
  void dispose() {
    _pages.dispose();
    TtsService.instance.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _syncPage() {
    if (!mounted) return;
    setState(() {
      _lessons = _pages.items;
      _loading = _pages.loading;
      _error = _pages.error;
    });
  }

  Future<void> _load() => _pages.load();
  Future<void> _refresh() => _pages.refresh();

  List get _filtered => _lessons;

  Future<void> _toggleSpeak(Map lesson) async {
    final id = lesson['id'];
    if (_speakingLessonId == id) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.stop();
    if (!mounted) return;
    setState(() => _speakingLessonId = id is int ? id : null);

    final text = [
      (lesson['title'] ?? '').toString(),
      (lesson['content'] ?? '').toString(),
    ].where((t) => t.isNotEmpty).join('. ');

    if (text.trim().isEmpty) {
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.speakLine(text);
    if (mounted) setState(() => _speakingLessonId = null);
  }

  Future<void> _toggleLessonAudio(String url) async {
    if (_activeAudioUrl == url) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _activeAudioUrl = null);
      return;
    }
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
    if (mounted) setState(() => _activeAudioUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Scaffold(
      appBar: JisrAppBar(
        title: 'دروس لولي الأمر',
        actions: [
          if (['teacher', 'specialist'].contains(_role)) IconButton(
            tooltip: 'إضافة درس لولي الأمر', icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLessonScreen(types: [], forParents: true)));
              if (result != null && mounted) await _load();
            },
          ),
          IconButton(
            icon: const Icon(AppIcons.refresh),
            tooltip: 'تحديث',
            onPressed: _load,
          ),
        ],
      ),
      bottomNavigationBar: const TeacherNavigationBar(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.brandBlue.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(AppIcons.parent, color: c.infoText, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دروس مخصصة لك',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.infoText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نصائح وإرشادات من المختصين لمساعدتك في التعامل مع ابنك',
                        style: TextStyle(
                          fontSize: 13,
                          color: c.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              style: const TextStyle(fontSize: 17),
              decoration: const InputDecoration(
                hintText: 'ابحث في الدروس...',
                prefixIcon: Icon(AppIcons.search),
              ),
              onChanged: (v) { setState(() => _query = v); _pages.search(v); },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(),
            ),
          ),
          ListPagination(controller: _pages),
        ],
      ),
    );
  }
}
