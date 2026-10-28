import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/class_lessons/class_lesson_catalog.dart';
import '../../services/class_assignment_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'class_assignment_controller.dart';
import 'class_assignment_form.dart';

class ClassAssignmentScreen extends StatelessWidget {
  const ClassAssignmentScreen({super.key, required this.section, this.gateway});
  final ClassLessonSection section;
  final ClassAssignmentGateway? gateway;
  @override
  Widget build(BuildContext context) => _ClassAssignmentBody(
    key: ValueKey((section, gateway)), section: section, gateway: gateway);
}

class _ClassAssignmentBody extends StatefulWidget {
  const _ClassAssignmentBody({super.key, required this.section, this.gateway});
  final ClassLessonSection section;
  final ClassAssignmentGateway? gateway;
  @override
  State<_ClassAssignmentBody> createState() => _ClassAssignmentBodyState();
}
class _ClassAssignmentBodyState extends State<_ClassAssignmentBody> with WidgetsBindingObserver {
  late final _state = ClassAssignmentController(widget.gateway ?? ClassAssignmentRepository(section: widget.section));
  String label(String ar, String en) => Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _state.reload(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<void> _confirm() async {
    if (!_state.canSubmit) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final expected = _state.options!, epoch = _state.generation, draft = _state.draft();
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(label('تأكيد إسناد الدرس', 'Confirm lesson assignment')),
      scrollable: true,
      content: Text('${widget.section.schoolName} / ${widget.section.yearName} / ${widget.section.name}\n'
        '${expected.lessons[draft.lessonId]}\n${label('عدد الطلاب', 'Students')}: ${draft.students.length}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
        TextButton(key: const ValueKey('class-assignment-confirm'), onPressed: () => Navigator.pop(context, true),
          child: Text(MaterialLocalizations.of(context).okButtonLabel))],
    ));
    if (mounted && yes == true) await _state.submit(expected, epoch, draft);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final options = _state.options, epoch = _state.generation;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(label('إسناد درس للشعبة', 'Assign class lesson'), softWrap: true),
        actions: [IconButton(tooltip: context.l10n.enrollmentReload,
          onPressed: _state.busy || _state.loading || _state.assignmentId != null ? null : _state.reload,
          icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('${widget.section.schoolName} / ${widget.section.yearName} / ${widget.section.name}'),
          const SizedBox(height: 12),
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(context.l10n, _state.error!))),
          if (_state.locked) Text(label('راجعي دروس الشعبة قبل محاولة جديدة. لن يُعاد الإسناد من هذه الشاشة.',
            'Review class lessons before another attempt. This screen will not resend the assignment.')),
          if (_state.assignmentId != null) ...[
            Text(label('تم تأكيد إسناد الدرس.', 'Lesson assignment confirmed.')),
            TextButton(key: const ValueKey('class-assignment-done'), onPressed: () => Navigator.pop(context, true),
              child: Text(label('العودة لدروس الشعبة', 'Return to class lessons'))),
          ],
          if (options != null && !options.canAssign) Text(label('إسناد الدروس غير متاح لك لهذه الشعبة.', 'Lesson assignment is unavailable to you for this section.')),
          if (options != null && options.canAssign && !_state.locked) ...[
            Text(label('سيُسند الدرس إلى جميع الطلاب المعروضين. ربط الهدف والتكييف اختياريان لكل طالب.',
              'Assign to every student shown. Each student’s goal link and adaptation are optional.')),
            ClassAssignmentForm(key: ValueKey(epoch), options: options, enabled: _state.editable,
              lessonId: _state.lessonId, goalIds: {for (final s in options.students) s.id: _state.goal(s.id)?.id ?? 0},
              adaptations: {for (final s in options.students) s.id: _state.adaptation(s.id)},
              onLesson: (id) => _state.chooseLesson(id, options, epoch),
              onGoal: (child, goal) => _state.chooseGoal(child, goal, options, epoch),
              onAdaptation: (child, text) => _state.adapt(child, text, options, epoch)),
            FilledButton(key: const ValueKey('class-assignment-submit'), onPressed: _state.canSubmit ? _confirm : null,
              child: Text(label('إسناد الدرس', 'Assign lesson'))),
          ],
        ]),
      ))),
    ));
  });
}
