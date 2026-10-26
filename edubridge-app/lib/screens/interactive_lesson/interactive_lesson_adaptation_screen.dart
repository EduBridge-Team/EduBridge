import 'package:flutter/material.dart';

import '../../models/interactive_lesson.dart';
import '../../services/interactive_draft_repository.dart';
import 'interactive_lesson_player.dart';

/// Local, unsaved adaptation preview; cannot publish or assign a learner.
class InteractiveLessonAdaptationScreen extends StatefulWidget {
  const InteractiveLessonAdaptationScreen({super.key, required this.template, this.savedDraft});

  final InteractiveLesson template;
  final InteractiveDraftSummary? savedDraft;

  @override
  State<InteractiveLessonAdaptationScreen> createState() =>
      _InteractiveLessonAdaptationScreenState();
}

class _InteractiveLessonAdaptationScreenState
    extends State<InteractiveLessonAdaptationScreen> {
  late final TextEditingController _title;
  late final TextEditingController _objective;
  bool _saving = false;
  bool _saved = false;
  SavedInteractiveDraft? _draft;
  bool _uncertain = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.savedDraft == null ? null : SavedInteractiveDraft(
      id: widget.savedDraft!.id, version: widget.savedDraft!.version,
    );
    _title = TextEditingController(text: widget.savedDraft?.title ?? widget.template.title);
    _objective = TextEditingController(text: widget.savedDraft?.objective ?? widget.template.objective);
  }

  @override
  void dispose() {
    _title.dispose();
    _objective.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _saved || _uncertain) return;
    final title = _title.text.trim();
    final objective = _objective.text.trim();
    if (title.isEmpty || objective.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان الدرس والنتاج التعليمي.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final receipt = await const InteractiveDraftRepository().save(
        templateId: widget.template.id,
        title: title,
        objective: objective,
        existing: _draft,
      );
      if (!mounted) return;
      setState(() {
        _draft = receipt;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المسودة في حسابك.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uncertain = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حالة الحفظ غير مؤكدة. راجع مسوداتك وأعد فتح الشاشة قبل محاولة جديدة.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              const Text('يمكن حفظ العنوان والنتاج كمسودة خاصة بك. لا يتم إسناد الدرس إلى طالب أو نشره.'),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('adapt-lesson-title'),
                controller: _title,
                enabled: !_saving,
                onChanged: (_) { if (_saved) setState(() => _saved = false); },
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'عنوان الدرس'),
              ),
              TextField(
                key: const ValueKey('adapt-lesson-objective'),
                controller: _objective,
                enabled: !_saving,
                onChanged: (_) { if (_saved) setState(() => _saved = false); },
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'النتاج التعليمي'),
              ),
              FilledButton.icon(
                key: const ValueKey('save-adapted-lesson'),
                onPressed: _saving || _saved || _uncertain ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'جارٍ الحفظ' : _saved ? 'تم الحفظ' : _uncertain ? 'تحقق من حالة المسودة' : _draft == null ? 'حفظ مسودة خاصة' : 'حفظ التعديلات'),
              ),
              const SizedBox(height: 12),
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
