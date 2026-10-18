import 'package:flutter/material.dart';
import '../../models/interactive_lesson.dart';

/// Accessible, RTL practice player. The caller controls lesson selection.
/// No scores or child details are uploaded by this widget.
class InteractiveLessonPlayer extends StatefulWidget {
  const InteractiveLessonPlayer({super.key, required this.lesson});
  final InteractiveLesson lesson;

  @override
  State<InteractiveLessonPlayer> createState() => _InteractiveLessonPlayerState();
}

class _InteractiveLessonPlayerState extends State<InteractiveLessonPlayer> {
  int _index = 0;
  String? _selected;
  bool _revealed = false;

  void _move(int delta) {
    setState(() {
      _index += delta;
      _selected = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.lesson.steps;
    final finished = _index == steps.length;
    final step = finished ? null : steps[_index];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.lesson.title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label: finished
                      ? 'اكتمل الدرس'
                      : 'الخطوة ${_index + 1} من ${steps.length}',
                  child: LinearProgressIndicator(
                    value: finished ? 1 : (_index + 1) / steps.length,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: finished
                      ? Center(
                          child: Text(
                            'أكملت الدرس! أحسنت.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        )
                      : SingleChildScrollView(
                          child: switch (step!) {
                            LessonExplanation(:final text) => Text(
                                text,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            LessonSingleChoice question => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    question.prompt,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  ...question.options.map(
                                    (option) => RadioListTile<String>(
                                      title: Text(option.text),
                                      value: option.id,
                                      groupValue: _selected,
                                      onChanged: _revealed
                                          ? null
                                          : (value) =>
                                              setState(() => _selected = value),
                                    ),
                                  ),
                                  if (_revealed)
                                    Semantics(
                                      liveRegion: true,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          question.isCorrect(_selected!)
                                              ? 'أحسنت! إجابة صحيحة.'
                                              : 'حاول مرة أخرى.',
                                        ),
                                      ),
                                    ),
                                  if (_selected != null && !_revealed)
                                    FilledButton(
                                      onPressed: () =>
                                          setState(() => _revealed = true),
                                      child: const Text('تحقق من الإجابة'),
                                    ),
                                  if (_revealed &&
                                      !question.isCorrect(_selected!))
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _selected = null;
                                        _revealed = false;
                                      }),
                                      child: const Text('حاول مرة أخرى'),
                                    ),
                                ],
                              ),
                          },
                        ),
                ),
                Row(
                  children: [
                    if (_index > 0)
                      OutlinedButton(
                        onPressed: () => _move(-1),
                        child: const Text('السابق'),
                      ),
                    const Spacer(),
                    if (finished)
                      FilledButton(
                        onPressed: () => setState(() {
                          _index = 0;
                          _selected = null;
                          _revealed = false;
                        }),
                        child: const Text('إعادة الدرس'),
                      )
                    else if (step is LessonExplanation ||
                        (step is LessonSingleChoice &&
                            _revealed &&
                            step.isCorrect(_selected!)))
                      FilledButton(
                        onPressed: () => _move(1),
                        child: Text(_index == steps.length - 1
                            ? 'إنهاء الدرس'
                            : 'التالي'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
