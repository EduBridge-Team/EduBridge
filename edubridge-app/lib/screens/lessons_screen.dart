// lib/screens/lessons_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/paged_list_controller.dart';
import '../widgets/list_pagination.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/speakable.dart';
import '../widgets/lesson_rating_sheet.dart';
import 'assistant_screen.dart';
import 'sign_language_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List _lessons = [];
  List<dynamic> _signs = const [];
  late final PagedListController _pages;
  bool _loading = true;
  String? _error;
  String _query = '';
  final _searchInput = TextEditingController();

  int? _speakingLessonId;

  @override
  void initState() {
    super.initState();
    _pages = PagedListController((page, query) => ApiService.getLessonsPage(page: page, query: query));
    _pages.addListener(_syncPage);
    _loadLessons();
    ApiService.getSignLanguageSigns().then((signs) {
      if (mounted) setState(() => _signs = signs);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _pages.dispose();
    _searchInput.dispose();
    TtsService.instance.stop();
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

  Future<void> _loadLessons() => _pages.load();


  Future<void> _toggleSpeak(Map lesson) async {
    final lessonId = lesson['id'];
    if (_speakingLessonId == lessonId) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.stop();
    if (!mounted) return;
    setState(() => _speakingLessonId = lessonId is int ? lessonId : null);

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

  String _buildLessonSpeech(Map lesson) {
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();

    final parts = <String>[
      'درس: $title',
      if (content.isNotEmpty) content,
      'اضغط لسماع الدرس',
    ];

    return parts.join('، ');
  }

  List get _filtered => _lessons;

  String _normalizeSignText(Object? value) {
    return (value ?? '')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<Map<String, dynamic>> _matchingSigns(Map lesson) {
    final haystack = _normalizeSignText(
      '${lesson['title'] ?? ''} ${lesson['content'] ?? ''}',
    );
    return _signs
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((sign) {
          final ar = _normalizeSignText(sign['arabic_label']);
          final en = _normalizeSignText(sign['english_label']);
          return (ar.isNotEmpty && haystack.contains(ar)) ||
              (en.isNotEmpty && haystack.contains(en));
        })
        .take(3)
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JisrAppBar(title: 'تصفح الدروس'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استكشف المحتوى',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: JisrColors.of(context).heading,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ابحث عن درس واستمع إليه أو اطلب مساعدة نور.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: JisrColors.of(context).muted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchInput,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن درس...',
                    prefixIcon: const Icon(AppIcons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'مسح البحث',
                            onPressed: () { _searchInput.clear(); setState(() => _query = ''); _pages.search(''); },
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                  ),
                  onChanged: (v) { setState(() => _query = v); _pages.search(v); },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sign_language_rounded),
                    label: const Text('قاموس لغة الإشارة الفلسطينية'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignLanguageScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLessons,
              child: _buildBody(),
            ),
          ),
          ListPagination(controller: _pages),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(fontSize: 16, color: AppColors.red)),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(AppIcons.refresh, size: 28),
                label: const Text('إعادة المحاولة',
                    style: TextStyle(fontSize: 18)),
                onPressed: _loadLessons,
              ),
            ),
          ],
        ),
      );
    }

    final lessons = _filtered;
    if (lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(AppIcons.lesson,
              size: 72, color: JisrColors.of(context).muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _query.trim().isEmpty ? 'لا توجد دروس بعد' : 'لا نتائج مطابقة لبحثك',
              style: TextStyle(
                  fontSize: 18, color: JisrColors.of(context).muted),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      itemCount: lessons.length,
      itemBuilder: (context, i) => _buildLessonCard(lessons[i]),
    );
  }

  Widget _buildLessonCard(Map lesson) {
    final isSpeaking = _speakingLessonId == lesson['id'];
    final content = (lesson['content'] ?? '').toString();
    final matchedSigns = _matchingSigns(lesson);
    final c = JisrColors.of(context);

    return Speakable(
      text: _buildLessonSpeech(lesson),
      radius: 24,
      onTap: null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: c.tintGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(AppIcons.lesson,
                        size: 28, color: AppColors.greenDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (lesson['title'] ?? '').toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.heading,
                      ),
                    ),
                  ),
                ],
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ],
              if (matchedSigns.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matchedSigns.map((sign) {
                    final arabic = (sign['arabic_label'] ?? '').toString();
                    return ActionChip(
                      avatar: const Icon(Icons.sign_language_rounded, size: 18),
                      label: Text(arabic),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignLanguageScreen(initialQuery: arabic),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: Icon(
                  isSpeaking
                      ? Icons.stop_circle_outlined
                      : AppIcons.volumeUp,
                ),
                label: Text(isSpeaking ? 'إيقاف الاستماع' : 'استمع للدرس'),
                onPressed: () => _toggleSpeak(lesson),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('تقييم'),
                      onPressed: () {
                        final lessonId = lesson['id'];
                        if (lessonId is int) {
                          showLessonRatingSheet(
                            context,
                            lessonId: lessonId,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(AppIcons.speech),
                      label: const Text('اسأل نور'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssistantScreen(
                            lessonContext: [
                              'عنوان الدرس: ${lesson['title'] ?? ''}',
                              if (content.isNotEmpty)
                                'محتوى الدرس: $content',
                            ].join('\n'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}