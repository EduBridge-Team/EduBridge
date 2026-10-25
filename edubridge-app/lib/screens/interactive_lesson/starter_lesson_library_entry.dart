import 'package:flutter/material.dart';

import 'interactive_lesson_starter_library.dart';

/// Educator-only navigation entry. Lessons remain read-only practice templates.
class StarterLessonLibraryEntry extends StatelessWidget {
  const StarterLessonLibraryEntry({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        key: const ValueKey('starter-lesson-library-entry'),
        icon: const Icon(Icons.auto_stories_outlined),
        label: const Text('معاينة الدروس التفاعلية الجاهزة'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const InteractiveLessonStarterLibrary(),
          ),
        ),
      );
}
