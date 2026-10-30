import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/class_lessons/class_lesson_result.dart';
import '../../services/class_result_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'class_result_controller.dart';
import 'class_result_form.dart';

class ClassResultScreen extends StatelessWidget {
  const ClassResultScreen({super.key, required this.source, this.gateway});
  final ClassResultSource source;
  final ClassResultGateway? gateway;
  @override
  Widget build(BuildContext context) => _ClassResultBody(key: ValueKey((source, gateway)), source: source, gateway: gateway);
}
class _ClassResultBody extends StatefulWidget {
  const _ClassResultBody({super.key, required this.source, this.gateway});
  final ClassResultSource source;
  final ClassResultGateway? gateway;
  @override
  State<_ClassResultBody> createState() => _ClassResultBodyState();
}
class _ClassResultBodyState extends State<_ClassResultBody> with WidgetsBindingObserver {
  late final _state = ClassResultController(widget.gateway ?? ClassResultRepository(source: widget.source));
  String label(String ar, String en) => Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _state.reload(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _state.reload(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<void> _confirm() async {
    if (!_state.canSubmit) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final expected = _state.options!, epoch = _state.generation, draft = _state.draft!;
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(label('تأكيد تسجيل النتيجة', 'Confirm student result')), scrollable: true,
      content: Text([
        widget.source.student.name,
        widget.source.lesson.title,
        '${label('الحالة', 'State')}: ${draft.state == 'completed' ? label('مكتمل', 'Completed') : label('قيد التقدم', 'In progress')}',
        lessonResultDay(draft.observedOn),
        draft.observation.trim(),
        if (draft.score != null)
          '${label('النتيجة', 'Score')}: ${draft.score} / ${draft.maximum}',
        if (draft.goalValue != null)
          '${label('قياس الهدف', 'Goal measurement')}: ${draft.goalValue} ${expected.goalUnit ?? ''}',
      ].join('\\n')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
        TextButton(key: const ValueKey('class-result-confirm'), onPressed: () => Navigator.pop(context, true),
          child: Text(MaterialLocalizations.of(context).okButtonLabel))],
    ));
    if (mounted && yes == true) await _state.submit(expected, epoch, draft);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final options = _state.options, epoch = _state.generation, source = widget.source;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(label('تسجيل نتيجة الطالب', 'Record student result'), softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload,
          onPressed: _state.loading || _state.busy || _state.resultId != null ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${source.section.schoolName} / ${source.section.yearName} / ${source.section.name}'),
          Text(source.lesson.title, style: Theme.of(context).textTheme.titleLarge),
          Text(source.student.name, style: Theme.of(context).textTheme.titleMedium),
          if (source.student.goalTitle != null) ...[
            Text(source.student.goalTitle!),
            Text(label('تُرفق الملاحظة دليلًا للهدف المرتبط. القياس العددي اختياري.',
              'The observation is evidence for the linked goal. A numeric measurement is optional.')),
          ],
          const SizedBox(height: 12),
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(context.l10n, _state.error!))),
          if (_state.locked) Text(label('راجعي نتائج الطالب قبل محاولة جديدة. لن يُعاد إرسال النتيجة من هذه الشاشة.',
            'Review student results before another attempt. This screen will not resend the result.')),
          if (_state.resultId != null) ...[
            Text(label('تم تأكيد تسجيل النتيجة.', 'Student result confirmed.')),
            TextButton(key: const ValueKey('class-result-done'), onPressed: () => Navigator.pop(context, true),
              child: Text(label('العودة لدروس الشعبة', 'Return to class lessons'))),
          ],
          if (options != null && !options.canRecord) Text(label('تسجيل النتائج غير متاح لك لهذا الإسناد.', 'Recording results is unavailable to you for this assignment.')),
          if (options != null && options.canRecord && !_state.locked) ...[
            ClassResultForm(key: ValueKey(epoch), options: options, enabled: _state.editable,
              state: _state.state, observedOn: _state.observedOn,
              values: {'score': _state.score, 'maximum': _state.maximum, 'measurement': _state.measurement, 'observation': _state.observation},
              onState: (s) => _state.change(options, epoch, () => _state.state = s),
              onDate: (d) => _state.change(options, epoch, () => _state.observedOn = d),
              onText: (field, value) => _state.change(options, epoch, () {
                switch (field) {
                  case 'score': _state.score = value;
                  case 'maximum': _state.maximum = value;
                  case 'measurement': _state.measurement = value;
                  case 'observation': _state.observation = value;
                }
              })),
            FilledButton(key: const ValueKey('class-result-submit'), onPressed: _state.canSubmit ? _confirm : null,
              child: Text(label('تسجيل النتيجة', 'Record result'))),
          ],
        ])),
      ))),
    ));
  });
}
