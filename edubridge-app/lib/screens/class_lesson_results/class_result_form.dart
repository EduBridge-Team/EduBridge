import 'package:flutter/material.dart';
import '../../model/class_lessons/class_lesson_result.dart';
import '../academics/academic_choice_field.dart';

class ClassResultForm extends StatelessWidget {
  const ClassResultForm({super.key, required this.options, required this.enabled,
    required this.state, required this.observedOn, required this.values,
    required this.onState, required this.onDate, required this.onText});
  final ClassResultOptions options;
  final bool enabled;
  final String? state;
  final DateTime? observedOn;
  final Map<String, String> values;
  final ValueChanged<String> onState;
  final ValueChanged<DateTime> onDate;
  final void Function(String field, String value) onText;
  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    String label(String ar, String en) => english ? en : ar;
    String stateLabel(String value) => value == 'completed' ? label('مكتمل', 'Completed') : label('قيد التقدم', 'In progress');
    Widget field(String name, String ar, String en, {bool note = false}) => TextFormField(
      key: ValueKey('class-result-$name'), initialValue: values[name] ?? '', enabled: enabled,
      keyboardType: note ? TextInputType.multiline : const TextInputType.numberWithOptions(decimal: true),
      minLines: note ? 2 : 1, maxLines: note ? null : 1, maxLength: note ? 2000 : null,
      decoration: InputDecoration(label: Text(label(ar, en))), onChanged: (value) => onText(name, value));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AcademicChoiceField(key: const ValueKey('class-result-state'), label: label('حالة الدرس', 'Lesson state'),
        options: {for (var i = 0; i < options.states.length; i++) i + 1: stateLabel(options.states[i])},
        value: state == null ? null : options.states.indexOf(state!) + 1, requiredMessage: '',
        onChanged: enabled ? (id) => onState(options.states[id - 1]) : null),
      OutlinedButton.icon(key: const ValueKey('class-result-date'), icon: const Icon(Icons.calendar_month),
        label: Text('${label('تاريخ الملاحظة', 'Observation date')}: ${observedOn == null ? '—' : lessonResultDay(observedOn!)}'),
        onPressed: !enabled ? null : () async {
          final day = await showDatePicker(context: context, initialDate: observedOn ?? options.latest,
            firstDate: options.earliest, lastDate: options.latest);
          if (context.mounted && day != null) onDate(day);
        }),
      field('score', 'العلامة (اختياري)', 'Score (optional)'),
      field('maximum', 'العلامة القصوى (مع العلامة)', 'Maximum (with score)'),
      if (options.goalUnit != null) ...[
        Text(label('قياس الهدف مستقل عن علامة الدرس.', 'Goal measurement is separate from the lesson score.')),
        field('measurement', 'قياس الهدف (اختياري) — ${options.goalUnit}', 'Goal measurement (optional) — ${options.goalUnit}'),
      ],
      field('observation', 'الملاحظة / دليل الأداء', 'Observation / performance evidence', note: true),
      Text(label('اختاري الحالة والتاريخ واكتبي الملاحظة. عند إدخال علامة، أدخلي العلامة القصوى أيضًا.',
        'Choose a state and date, and enter an observation. A score also requires its maximum.')),
    ]);
  }
}
