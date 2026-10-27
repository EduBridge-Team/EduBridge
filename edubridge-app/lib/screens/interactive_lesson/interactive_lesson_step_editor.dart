import 'package:flutter/material.dart';
import '../../models/interactive_lesson.dart';
import 'interactive_lesson_player.dart';

/// A local-only step editor for educator previews.
///
/// No persistence or publication occurs until a dedicated API is integrated.
class InteractiveLessonStepEditor extends StatefulWidget {
  const InteractiveLessonStepEditor({super.key, required this.template});
  final InteractiveLesson template;

  @override
  State<InteractiveLessonStepEditor> createState() => _InteractiveLessonStepEditorState();
}

class _InteractiveLessonStepEditorState extends State<InteractiveLessonStepEditor> {
  late final List<InteractiveLessonStep> _steps;
  int _sequence = 0;

  @override
  void initState() {
    super.initState();
    _steps = List.of(widget.template.steps);
  }

  String _newId() => 'edited-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  Future<void> _addExplanation() async {
    var explanation = '';
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة خطوة شرح'),
        content: TextField(
          key: const ValueKey('lesson-step-explanation-input'),
          onChanged: (value) => explanation = value,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'نص الشرح'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, explanation.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (!mounted || text == null || text.isEmpty) return;
    setState(() => _steps.add(LessonExplanation(_newId(), text)));
  }

  Future<void> _addQuestion() async {
    var prompt = '';
    var first = '';
    var second = '';
    var answerIndex = 0;
    final result = await showDialog<(String, String, String, int)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('إضافة سؤال اختيار'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(key: const ValueKey('lesson-question-prompt'), onChanged: (value) => prompt = value,
                decoration: const InputDecoration(labelText: 'نص السؤال')),
              TextField(key: const ValueKey('lesson-question-first'), onChanged: (value) => first = value,
                decoration: const InputDecoration(labelText: 'الخيار الأول')),
              TextField(key: const ValueKey('lesson-question-second'), onChanged: (value) => second = value,
                decoration: const InputDecoration(labelText: 'الخيار الثاني')),
              DropdownButtonFormField<int>(
                initialValue: answerIndex,
                decoration: const InputDecoration(labelText: 'الإجابة الصحيحة'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('الخيار الأول')),
                  DropdownMenuItem(value: 1, child: Text('الخيار الثاني')),
                ],
                onChanged: (value) => update(() => answerIndex = value ?? 0),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext,
                (prompt.trim(), first.trim(), second.trim(), answerIndex)),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;
    final (question, optionA, optionB, correct) = result;
    if (question.isEmpty || optionA.isEmpty || optionB.isEmpty || optionA == optionB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل سؤالًا وخيارين مختلفين.')),
      );
      return;
    }
    setState(() => _steps.add(LessonSingleChoice(_newId(), question, [
      LessonOption('a', optionA), LessonOption('b', optionB),
    ], correct == 0 ? 'a' : 'b')));
  }

  void _preview() {
    if (_steps.isEmpty) return;
    final lesson = InteractiveLesson(
      id: widget.template.id, subject: widget.template.subject,
      title: widget.template.title, objective: widget.template.objective,
      steps: List.unmodifiable(_steps),
    );
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => InteractiveLessonPlayer(lesson: lesson),
    ));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تحرير خطوات الدرس')),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('التغييرات للمعاينة فقط ولا تُحفظ أو تُنشر.'),
        ),
        Expanded(child: ReorderableListView.builder(
          itemCount: _steps.length,
          onReorder: (oldIndex, newIndex) => setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final step = _steps.removeAt(oldIndex);
            _steps.insert(newIndex, step);
          }),
          itemBuilder: (context, index) {
            final step = _steps[index];
            return ListTile(
              key: ValueKey(step.id),
              title: Text(switch (step) {
                LessonExplanation(:final text) => text,
                LessonSingleChoice(:final prompt) => prompt,
              }),
              leading: const Icon(Icons.drag_handle),
              trailing: IconButton(
                tooltip: 'حذف الخطوة',
                onPressed: () => setState(() => _steps.removeAt(index)),
                icon: const Icon(Icons.delete_outline),
              ),
            );
          },
        )),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: _addExplanation,
              icon: const Icon(Icons.notes), label: const Text('إضافة شرح')),
            OutlinedButton.icon(onPressed: _addQuestion,
              icon: const Icon(Icons.quiz_outlined), label: const Text('إضافة سؤال')),
            FilledButton.icon(onPressed: _steps.isEmpty ? null : _preview,
              icon: const Icon(Icons.play_arrow), label: const Text('معاينة')),
          ]),
        ),
      ]),
    ),
  );
}
