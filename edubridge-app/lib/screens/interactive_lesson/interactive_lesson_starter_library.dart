import 'package:flutter/material.dart';

import '../../models/interactive_lesson.dart';
import '../../services/interactive_lesson_starter_repository.dart';
import 'interactive_lesson_player.dart';

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
        appBar: AppBar(title: const Text('الدروس التفاعلية الجاهزة')),
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
                    trailing: const Icon(Icons.chevron_left),
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
