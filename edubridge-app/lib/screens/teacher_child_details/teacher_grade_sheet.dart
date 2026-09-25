// lib/screens/teacher_child_details/teacher_grade_sheet.dart
part of 'teacher_child_details_screen.dart';

class _GradeHomeworkSheet extends StatefulWidget {
  final Homework homework;
  final HomeworkSubmission submission;

  const _GradeHomeworkSheet({
    required this.homework,
    required this.submission,
  });

  @override
  State<_GradeHomeworkSheet> createState() => _GradeHomeworkSheetState();
}

class _GradeHomeworkSheetState extends State<_GradeHomeworkSheet> {
  final _gradeCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.submission.grade != null) {
      _gradeCtrl.text = widget.submission.grade.toString();
    }
    if (widget.submission.feedback != null) {
      _feedbackCtrl.text = widget.submission.feedback!;
    }
  }

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final gradeText = _gradeCtrl.text.trim();
    if (gradeText.isEmpty) {
      setState(() => _error = 'الدرجة مطلوبة');
      return;
    }
    final grade = int.tryParse(gradeText);
    if (grade == null || grade < 0 || grade > 100) {
      setState(() => _error = 'الدرجة يجب أن تكون بين 0 و 100');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final ok = await ApiService.gradeHomework(
        submissionId: widget.submission.id,
        grade: grade,
        feedback: _feedbackCtrl.text.trim().isEmpty
            ? null
            : _feedbackCtrl.text.trim(),
      );

      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التصحيح وإرساله للطالب'),
            backgroundColor: AppColors.brandTealDeep,
          ),
        );
      } else {
        setState(() {
          _error = 'فشل حفظ التصحيح';
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.grade, color: AppColors.brandTealDeep, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تصحيح: ${widget.homework.title}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStudentAnswerBox(c),
              const SizedBox(height: 16),
              TextField(
                controller: _gradeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الدرجة (0-100) *',
                  prefixIcon: Icon(AppIcons.starFilled),
                  hintText: 'مثال: 85',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظتك للطالب (اختياري)',
                  prefixIcon: Icon(AppIcons.chat),
                  alignLabelWithHint: true,
                  hintText: 'مثال: عمل ممتاز، لكن راجع النقطة الثانية',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(AppIcons.check),
                      label: Text(
                        _saving ? 'جارٍ الحفظ...' : 'حفظ التصحيح',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAnswerBox(JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tintTeal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجابة الطالب:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: c.onTint,
            ),
          ),
          const SizedBox(height: 6),
          if (widget.submission.textAnswer != null &&
              widget.submission.textAnswer!.isNotEmpty)
            Text(
              widget.submission.textAnswer!,
              style: TextStyle(fontSize: 14, color: c.onTint, height: 1.5),
            )
          else
            Text(
              '— لم يكتب إجابة نصية —',
              style: TextStyle(
                fontSize: 13,
                color: c.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}