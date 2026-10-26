import 'package:flutter/material.dart';

import '../../models/interactive_lesson.dart';
import 'interactive_lesson_player.dart';

/// Local, unsaved adaptation preview; cannot publish or assign a learner.
class InteractiveLessonAdaptationScreen extends StatefulWidget {
  const InteractiveLessonAdaptationScreen({super.key, required this.template});

  final InteractiveLesson template;

  @override
  State<InteractiveLessonAdaptationScreen> createState() =>
      _InteractiveLessonAdaptationScreenState();
}

class _InteractiveLessonAdaptationScreenState
    extends State<InteractiveLessonAdaptationScreen> {
  late final TextEditingController _title;
  late final TextEditingController _objective;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.template.title);
    _objective = TextEditingController(text: widget.template.objective);
  }

  @override
  void dispose() {
    _title.dispose();
    _objective.dispose();
    super.dispose();
  }

  void _preview() {
    final title = _title.text.trim();
    final objective = _objective.text.trim();
    if (title.isEmpty || objective.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان الدرس والنتاج التعليمي.')),
      );
      return;
    }
    final adapted = InteractiveLesson(
      id: widget.template.id,
      subject: widget.template.subject,
      title: title,
      objective: objective,
      steps: widget.template.steps,
    );
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => InteractiveLessonPlayer(lesson: adapted),
    ));
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('تخصيص نسخة للمعاينة')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('هذه معاينة محلية فقط. لن يتم حفظ التغييرات أو إسناد الدرس إلى طالب.'),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('adapt-lesson-title'),
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'عنوان الدرس'),
              ),
              TextField(
                key: const ValueKey('adapt-lesson-objective'),
                controller: _objective,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'النتاج التعليمي'),
              ),
              FilledButton.icon(
                key: const ValueKey('preview-adapted-lesson'),
                onPressed: _preview,
                icon: const Icon(Icons.play_arrow),
                label: const Text('معاينة النسخة المعدّلة'),
              ),
            ],
          ),
        ),
      );
}
