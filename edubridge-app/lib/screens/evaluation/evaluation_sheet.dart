// lib/screens/evaluation/evaluation_sheet.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../services/approval_service.dart';
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

class _EvaluationSheetState extends State<EvaluationSheet> {
  void _refreshState(VoidCallback callback) => setState(callback);

  final _formKey = GlobalKey<FormState>();

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
  String? _error;

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
    if (!_formKey.currentState!.validate()) return;

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

      final result = await ApiService.evaluateChild(
        childId: widget.child['id'],
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

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'فشل حفظ التقييم';
          _loading = false;
        });
        return;
      }

      final updatedChild = widget.child;
      updatedChild['status'] = 'evaluated';
      if (_selectedTeacherId != null) {
        updatedChild['status'] = 'assigned';
        updatedChild['assigned_teacher_id'] = _selectedTeacherId;
        final teacher = widget.teachers.firstWhere(
          (t) => t['id'] == _selectedTeacherId,
          orElse: () => {},
        );
        updatedChild['assigned_teacher_name'] = teacher['name'] ?? '';
      }
      widget.onSaved(updatedChild);

      if (_sendToMinistry) {
        await _handleMinistryFlow(result, teachingMethods);
      } else {
        await _handleDirectToTeacherFlow(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _handleMinistryFlow(
    Map<String, dynamic> result,
    List<String> teachingMethods,
  ) async {
    await ApprovalService.submitForApproval(
      childId: widget.child['id'],
      childName: widget.child['name'] ?? '',
      evaluationId: result['id'] ?? 0,
      evaluationData: result,
      teacherId: _selectedTeacherId,
      teacherName: widget.teachers
              .firstWhere(
                (t) => t['id'] == _selectedTeacherId,
                orElse: () => {'name': ''},
              )['name']
              ?.toString() ??
          '',
      educationalPlan: _educationalPlanCtrl.text.trim(),
      cognitiveAssessment: _cognitiveCtrl.text.trim(),
      motorAssessment: _motorCtrl.text.trim(),
      emotionalAssessment: _emotionalCtrl.text.trim(),
      socialAssessment: _socialCtrl.text.trim(),
      recommendations: _recommendationsCtrl.text.trim(),
      teachingMethods: teachingMethods,
    );

    if (!mounted) return;

    _showSuccessDialog(
      icon: AppIcons.upload,
      iconColor: AppColors.orange,
      title: 'تم الإرسال للوزارة',
      message: 'سيتم مراجعة الخطة من الوزارة.\n\n'
          '• عند الموافقة: يُشعَر المعلم والمعلمون المعنيون\n'
          '• عند الرفض: تعود إليك الخطة للتعديل',
    );

    if (mounted) Navigator.pop(context, true);
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

    _showSuccessDialog(
      icon: AppIcons.check,
      iconColor: AppColors.green,
      title: 'تم التقييم بنجاح',
      message: _selectedTeacherId != null
          ? 'تم إرسال التقييم للمعلم المسؤول لبدء التنفيذ مباشرة.'
          : 'تم حفظ التقييم. يمكن تعيين معلم لاحقاً.',
    );

    if (mounted) Navigator.pop(context, true);
  }

  void _showSuccessDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
                child: const Text('حسناً'),
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
