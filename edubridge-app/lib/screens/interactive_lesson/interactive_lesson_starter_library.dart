import 'package:flutter/material.dart';

import '../../models/interactive_lesson.dart';
import '../../services/interactive_lesson_starter_repository.dart';
import 'interactive_lesson_player.dart';
import 'interactive_lesson_adaptation_screen.dart';
import 'interactive_lesson_saved_drafts_screen.dart';
import 'interactive_lesson_step_editor.dart';

/// Standalone preview of the starter templates.
/// No backend publishing, assignment or progress writes occur here.
class InteractiveLessonStarterLibrary extends StatelessWidget {
  const InteractiveLessonStarterLibrary({super.key, this.repository});

  final InteractiveLessonStarterRepository? repository;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
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
          future: (repository ?? const InteractiveLessonStarterRepository()).load(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('تعذّر تحميل الدروس. حاول مجددًا.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final lessons = snapshot.data!.templates;
            if (lessons.isEmpty) {
              return const Center(child: Text('لا توجد دروس جاهزة حاليًا.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  child: ListTile(
                    title: Text(lesson.title),
                    subtitle: Text(lesson.objective),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        key: ValueKey('edit-lesson-steps-${lesson.id}'),
                        tooltip: 'تحرير الخطوات للمعاينة',
                        icon: const Icon(Icons.format_list_numbered),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => InteractiveLessonStepEditor(template: lesson),
                        )),
                      ),
                      IconButton(
                      key: ValueKey('adapt-lesson-${lesson.id}'),
                      tooltip: 'تخصيص للمعاينة',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InteractiveLessonAdaptationScreen(template: lesson),
                        ),
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
            );
          },
        ),
      ),
    );
  }
}
