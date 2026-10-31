import '../../utils/locale_form_validation.dart';
import '../../model/evaluations/evaluation_save_receipt.dart';
import '../../model/evaluations/ministry_submission_receipt.dart';
import '../../l10n/l10n.dart';
// lib/screens/evaluation/evaluation_sheet.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/safe_bottom.dart';

part 'evaluation_ministry_toggle.dart';
part 'evaluation_fields.dart';

class EvaluationSheet extends StatefulWidget {
  final Map child;
  final List teachers;
  final void Function(Map) onSaved;

  const EvaluationSheet({
    super.key,
    required this.child,
    required this.teachers,
    required this.onSaved,
  });

  @override
  State<EvaluationSheet> createState() => _EvaluationSheetState();
}

class _EvaluationSheetState extends State<EvaluationSheet> with LocaleFormValidation<EvaluationSheet> {
  void _refreshState(VoidCallback callback) => setState(callback);

  final _formKey = GlobalKey<FormState>();
  @override
  GlobalKey<FormState> get validationFormKey => _formKey;

  final _cognitiveCtrl = TextEditingController();
  final _motorCtrl = TextEditingController();
  final _emotionalCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();
  final _educationalPlanCtrl = TextEditingController();
  final _teachingMethodsCtrl = TextEditingController();

  String _evaluationType = 'initial';
  int? _selectedTeacherId;
  bool _loading = false;
  Object? _error;
  Map<String, dynamic>? _savedEvaluation;
  int? _savedEvaluationChildId;
  int _childGeneration = 0;

  @override
  void didUpdateWidget(covariant EvaluationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child['id'] != widget.child['id']) {
      _childGeneration++;
      _savedEvaluation = null;
      _savedEvaluationChildId = null;
      _error = null;
      _loading = false;
      _sendToMinistry = false;
      _selectedTeacherId = null;
      _evaluationType = 'initial';
      for (final controller in [
        _cognitiveCtrl, _motorCtrl, _emotionalCtrl, _socialCtrl,
        _recommendationsCtrl, _educationalPlanCtrl, _teachingMethodsCtrl,
      ]) { controller.clear(); }
    }
  }

  bool _sendToMinistry = false;

  @override
  void dispose() {
    _cognitiveCtrl.dispose();
    _motorCtrl.dispose();
    _emotionalCtrl.dispose();
    _socialCtrl.dispose();
    _recommendationsCtrl.dispose();
    _educationalPlanCtrl.dispose();
    _teachingMethodsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !validateLocalizedForm()) return;
    final childId = widget.child['id'];
    final childGeneration = _childGeneration;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final teachingMethods = _teachingMethodsCtrl.text.trim().isNotEmpty
          ? _teachingMethodsCtrl.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : ['عام'];

      final result = (_savedEvaluationChildId == childId ? _savedEvaluation : null) ?? await ApiService.evaluateChild(
        childId: childId,
        evaluationType: _evaluationType,
        cognitiveAssessment: _cognitiveCtrl.text.trim(),
        motorAssessment: _motorCtrl.text.trim(),
        emotionalAssessment: _emotionalCtrl.text.trim(),
        socialAssessment: _socialCtrl.text.trim(),
        recommendations: _recommendationsCtrl.text.trim(),
        assignedTeacherId: _selectedTeacherId,
        educationalPlan: _educationalPlanCtrl.text.trim(),
        teachingMethods: teachingMethods,
      );

      if (!mounted || childGeneration != _childGeneration) return;

      if (result == null) {
        setState(() {
          _error = SharedUiMessage.evaluationSaveFailed;
          _loading = false;
        });
        return;
      }

      // A write is confirmed only by a usable record for the requested child.
      // Older responses may omit child_id, but must never contradict it.
      if (!evaluationSaveReceiptMatchesChild(result, childId)) {
        setState(() {
          _error = SharedUiMessage.evaluationSaveFailed;
          _loading = false;
        });
        return;
      }

      // Reuse only a verified save receipt if ministry submission needs a retry.
      _savedEvaluation = result;
      _savedEvaluationChildId = childId as int;
      if (_sendToMinistry) {
        final submitted = await ApiService.submitForMinistryApproval(
          childId: childId,
          evaluationId: result['id'],
          educationalPlan: _educationalPlanCtrl.text.trim(),
          cognitiveAssessment: _cognitiveCtrl.text.trim(),
          motorAssessment: _motorCtrl.text.trim(),
          emotionalAssessment: _emotionalCtrl.text.trim(),
          socialAssessment: _socialCtrl.text.trim(),
          recommendations: _recommendationsCtrl.text.trim(),
          teachingMethods: teachingMethods,
          teacherId: _selectedTeacherId,
        );
        if (!mounted || childGeneration != _childGeneration) return;
        if (submitted == null ||
            !ministrySubmissionReceiptMatches(submitted,
              childId: childId as int,
              evaluationId: result['id'] as int)) {
          setState(() {
            _error = SharedUiMessage.changesSaveFailed;
            _loading = false;
          });
          return;
        }
      }

      // Do not mutate the input map; publish changes only after server confirmation.
      final updatedChild = Map<String, dynamic>.from(widget.child);
      updatedChild['status'] = _selectedTeacherId == null ? 'evaluated' : 'assigned';
      if (_selectedTeacherId != null) {
        updatedChild['assigned_teacher_id'] = _selectedTeacherId;
        final teacher = widget.teachers.firstWhere(
          (t) => t['id'] == _selectedTeacherId,
          orElse: () => {},
        );
        updatedChild['assigned_teacher_name'] = teacher['name'] ?? '';
      }
      widget.onSaved(updatedChild);

      if (_sendToMinistry) {
        await _showSuccessDialog(
          icon: AppIcons.upload,
          iconColor: AppColors.orange,
          title: context.l10n.evaluationSentToMinistry,
          message: context.l10n.ministryEvaluationSuccessDetails,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        await _handleDirectToTeacherFlow(result);
      }
    } catch (e) {
      if (!mounted || childGeneration != _childGeneration) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _handleDirectToTeacherFlow(
    Map<String, dynamic> result,
  ) async {
    if (_selectedTeacherId != null) {
      try {
        await ApiService.authPost('/notifications/send', {
          'user_id': _selectedTeacherId,
          'child_id': widget.child['id'],
          'evaluation_id': result['id'],
          'title': 'تقييم جديد للطفل',
          'body':
              'رفع المختص تقييماً للطفل "${widget.child['name']}" — راجع الخطة وابدأ التنفيذ',
          'type': 'evaluation_created',
        });
      } catch (_) {
        debugPrint('فشل إرسال إشعار للمعلم');
      }
    }

    if (!mounted) return;

    await _showSuccessDialog(
      icon: AppIcons.check,
      iconColor: AppColors.brandTealDeep,
      title: context.l10n.evaluationCompleted,
      message: _selectedTeacherId != null
          ? context.l10n.evaluationSentToTeacher
          : context.l10n.evaluationSavedAssignLater,
    );

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _showSuccessDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    setState(() => _loading = false);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.l10n.acknowledge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final childName = widget.child['name'] ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: safeModalBottom(context)),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(c, childName),
                const SizedBox(height: 8),
                _buildInfoBanner(c),
                const SizedBox(height: 16),
                _buildEvaluationTypeDropdown(),
                const SizedBox(height: 16),
                _buildCognitiveField(),
                const SizedBox(height: 16),
                _buildMotorField(),
                const SizedBox(height: 16),
                _buildEmotionalField(),
                const SizedBox(height: 16),
                _buildSocialField(),
                const SizedBox(height: 16),
                _buildRecommendationsField(),
                const SizedBox(height: 16),
                _buildEducationalPlanField(),
                const SizedBox(height: 16),
                _buildTeachingMethodsField(),
                const SizedBox(height: 16),
                _buildTeacherDropdown(),
                const SizedBox(height: 8),
                _buildTeacherHint(c),
                const SizedBox(height: 16),
                buildMinistryToggleCard(
                  context: context,
                  c: c,
                  active: _sendToMinistry,
                  onChanged: (v) => setState(() => _sendToMinistry = v),
                ),
                if (_error != null) _buildErrorBox(),
                const SizedBox(height: 20),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
