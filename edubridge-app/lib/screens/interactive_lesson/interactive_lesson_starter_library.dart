import '../../theme.dart';
import 'package:flutter/material.dart';

import '../../models/interactive_lesson.dart';
import '../../services/interactive_lesson_starter_repository.dart';
import 'interactive_lesson_player.dart';
import 'interactive_lesson_adaptation_screen.dart';
import 'interactive_lesson_saved_drafts_screen.dart';

/// Standalone preview of the starter templates.
/// No backend publishing, assignment or progress writes occur here.
class InteractiveLessonStarterLibrary extends StatefulWidget {
  const InteractiveLessonStarterLibrary({super.key, this.repository});

  final InteractiveLessonStarterRepository? repository;

  @override
  State<InteractiveLessonStarterLibrary> createState() => _InteractiveLessonStarterLibraryState();
}

class _InteractiveLessonStarterLibraryState extends State<InteractiveLessonStarterLibrary> {
  String _query = '';
  String _subject = 'all';
  late final Future<InteractiveLessonCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = (widget.repository ?? const InteractiveLessonStarterRepository()).load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: BrandAppBar(
          title: const Text('الدروس التفاعلية الجاهزة'),
          actions: [
            IconButton(
              key: const ValueKey('open-saved-lesson-drafts'),
              tooltip: 'مسوداتي المحفوظة',
              icon: const Icon(Icons.folder_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InteractiveLessonSavedDraftsScreen(),
                ),
              ),
            ),
          ],
        ),
        body: FutureBuilder<InteractiveLessonCatalog>(
          future: _catalog,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('تعذّر تحميل الدروس. حاول مجددًا.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final lessons = snapshot.data!.templates.where((lesson) {
              final q = _query.trim().toLowerCase();
              final matchesText = q.isEmpty || lesson.title.toLowerCase().contains(q) || lesson.objective.toLowerCase().contains(q);
              return matchesText && (_subject == 'all' || lesson.subject == _subject);
            }).toList();
            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  TextField(
                    key: const ValueKey('search-interactive-lessons'),
                    decoration: const InputDecoration(labelText: 'البحث في الدروس', prefixIcon: Icon(Icons.search)),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('filter-interactive-lessons-subject'),
                    initialValue: _subject,
                    decoration: const InputDecoration(labelText: 'المادة'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('جميع المواد')),
                      DropdownMenuItem(value: 'arabic', child: Text('اللغة العربية')),
                      DropdownMenuItem(value: 'math', child: Text('الرياضيات')),
                      DropdownMenuItem(value: 'life_skills', child: Text('المهارات الحياتية')),
                    ],
                    onChanged: (value) { if (value != null) setState(() => _subject = value); },
                  ),
                ]),
              ),
              Expanded(child: lessons.isEmpty
                ? const Center(child: Text('لا توجد دروس مطابقة للبحث.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  child: ListTile(
                    title: Text(lesson.title),
                    subtitle: Text(lesson.objective),
                    trailing: IconButton(
                      key: ValueKey('adapt-lesson-${lesson.id}'),
                      tooltip: 'تخصيص للمعاينة',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InteractiveLessonAdaptationScreen(template: lesson),
                        ),
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => InteractiveLessonPlayer(lesson: lesson),
                      ),
                    ),
                  ),
                );
              },
            )),
            ]);
          },
        ),
      ),
    );
  }
}
