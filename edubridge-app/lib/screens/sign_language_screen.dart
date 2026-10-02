import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'assistant_screen.dart';

class SignLanguageScreen extends StatefulWidget {
  final String initialQuery;

  const SignLanguageScreen({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<SignLanguageScreen> createState() => _SignLanguageScreenState();
}

class _SignLanguageScreenState extends State<SignLanguageScreen> {
  late final TextEditingController _search;
  List<dynamic> _signs = const [];
  List<dynamic> _categories = const [];
  String _category = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
    _loadCategories();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await ApiService.getSignLanguageCategories();
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final signs = await ApiService.getSignLanguageSigns(
        query: _search.text.trim(),
        category: _category.isEmpty ? null : _category,
      );
      if (!mounted) return;
      setState(() => _signs = signs);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'math':
        return 'الرياضيات';
      case 'science':
        return 'العلوم';
      default:
        return value;
    }
  }

  void _openSign(Map<String, dynamic> sign) {
    final arabic = (sign['arabic_label'] ?? '').toString();
    final english = (sign['english_label'] ?? '').toString();
    final mediaUrl = sign['media_url']?.toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤟', style: TextStyle(fontSize: 52)),
              Text(arabic, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: JisrColors.of(context).heading)),
              const SizedBox(height: 4),
              Text(english, style: TextStyle(color: JisrColors.of(context).muted)),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: JisrColors.of(context).card, borderRadius: BorderRadius.circular(18), border: Border.all(color: JisrColors.of(context).line)),
                child: Column(
                  children: [
                    Icon(mediaUrl == null || mediaUrl.isEmpty ? Icons.video_library_outlined : Icons.play_circle_outline_rounded, size: 36, color: AppColors.greenDeep),
                    const SizedBox(height: 8),
                    Text(mediaUrl == null || mediaUrl.isEmpty ? 'الفيديو الأصلي غير متاح بعد' : 'فيديو الإشارة متاح', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (mediaUrl == null || mediaUrl.isEmpty)
                      const Padding(padding: EdgeInsets.only(top: 5), child: Text('سيظهر هنا تلقائياً عند إضافة الوسائط الأصلية.', textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('اسأل نور عن هذا المفهوم'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => AssistantScreen(
                          lessonContext: 'اشرح مفهوم "$arabic" ($english) بطريقة تعليمية مبسطة، وهو مدخل في قاموس لغة الإشارة الفلسطينية داخل EduBridge.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Scaffold(
      appBar: const JisrAppBar(title: 'لغة الإشارة الفلسطينية'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🤟', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 6),
                  Text('قاموس لغة الإشارة الفلسطينية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.heading)),
                  const SizedBox(height: 6),
                  Text('مفاهيم تعليمية في الرياضيات والعلوم. الفيديوهات ستظهر تلقائياً عند توفر المصدر الأصلي.', style: TextStyle(height: 1.55, color: c.muted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث بالعربية أو الإنجليزية...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); _load(); setState(() {}); }, icon: const Icon(Icons.close_rounded)),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(label: const Text('الكل'), selected: _category.isEmpty, onSelected: (_) { setState(() => _category = ''); _load(); }),
                ..._categories.map((item) {
                  final value = (item['category'] ?? '').toString();
                  return ChoiceChip(
                    label: Text('${_categoryLabel(value)} (${item['total'] ?? 0})'),
                    selected: _category == value,
                    onSelected: (_) { setState(() => _category = value); _load(); },
                  );
                }),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 10), OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة'))]),
              )
            else if (_signs.isEmpty)
              const Padding(padding: EdgeInsets.all(36), child: Center(child: Text('لا توجد إشارات مطابقة')))
            else
              ..._signs.map((raw) {
                final sign = Map<String, dynamic>.from(raw as Map);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => _openSign(sign),
                    leading: Container(
                      width: 48, height: 48, alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.tintGreen, borderRadius: BorderRadius.circular(14)),
                      child: const Text('🤟', style: TextStyle(fontSize: 23)),
                    ),
                    title: Text((sign['arabic_label'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${sign['english_label'] ?? ''} • ${_categoryLabel((sign['category'] ?? '').toString())}'),
                    trailing: Icon(sign['media_url'] == null ? Icons.video_library_outlined : Icons.play_circle_outline_rounded),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
