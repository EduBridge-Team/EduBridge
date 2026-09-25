// lib/screens/evaluation/evaluation_sheet.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../services/approval_service.dart';
import '../../theme.dart';
import '../../utils/safe_bottom.dart';

part 'evaluation_ministry_toggle.dart';

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
      iconColor: AppColors.brandBlueLight,
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
      builder: (_) => AlertDialog(
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
                onPressed: () => Navigator.pop(_),
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

  Widget _buildHeader(JisrColors c, String childName) {
    return Row(
      children: [
        const Icon(AppIcons.evaluate, color: AppColors.brandBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'تقييم $childName',
            style: TextStyle(
              fontSize: 20,
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
    );
  }

  Widget _buildInfoBanner(JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tintOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.info, color: AppColors.brandBlueLight, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'اختر في الأسفل: هل تُرسل الخطة للوزارة للموافقة، أم تُرسل للمعلم مباشرة؟',
              style: TextStyle(
                fontSize: 12.5,
                color: c.onTint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _evaluationType,
      decoration: const InputDecoration(
        labelText: 'نوع التقييم *',
        prefixIcon: Icon(AppIcons.filter),
      ),
      items: const [
        DropdownMenuItem(value: 'initial', child: Text('تقييم أولي')),
        DropdownMenuItem(value: 'follow_up', child: Text('متابعة')),
        DropdownMenuItem(value: 'final', child: Text('تقييم نهائي')),
      ],
      onChanged: (v) => setState(() => _evaluationType = v ?? 'initial'),
    );
  }

  Widget _buildCognitiveField() {
    return TextFormField(
      controller: _cognitiveCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'التقييم المعرفي *',
        prefixIcon: Icon(AppIcons.cognitive),
        hintText: 'مستوى التفكير، الانتباه، الذاكرة، ...',
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildMotorField() {
    return TextFormField(
      controller: _motorCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'التقييم الحركي *',
        prefixIcon: Icon(AppIcons.motor),
        hintText: 'المهارات الحركية الدقيقة والخشنة، ...',
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildEmotionalField() {
    return TextFormField(
      controller: _emotionalCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'التفاعل أثناء التعلم *',
        prefixIcon: Icon(AppIcons.speech),
        hintText: 'التفاعل مع الأنشطة، الاستجابة للتوجيه، المشاركة، ...',
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildSocialField() {
    return TextFormField(
      controller: _socialCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'التقييم الاجتماعي *',
        prefixIcon: Icon(AppIcons.users),
        hintText: 'التفاعل مع الآخرين، المهارات الاجتماعية، ...',
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildRecommendationsField() {
    return TextFormField(
      controller: _recommendationsCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'التوصيات *',
        prefixIcon: Icon(AppIcons.info),
        hintText: 'توصيات للمعلم وولي الأمر، ...',
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildEducationalPlanField() {
    return TextFormField(
      controller: _educationalPlanCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'الخطة التعليمية *',
        prefixIcon: Icon(AppIcons.plan),
        hintText: 'الخطة الدراسية المقترحة، ...',
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildTeachingMethodsField() {
    return TextFormField(
      controller: _teachingMethodsCtrl,
      decoration: const InputDecoration(
        labelText: 'طرق التدريس (اختياري)',
        prefixIcon: Icon(AppIcons.lesson),
        hintText: 'أدخل الطرق مفصولة بفواصل، مثال: بصري، سمعي،...',
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return DropdownButtonFormField<int?>(
      initialValue: _selectedTeacherId,
      decoration: const InputDecoration(
        labelText: 'تعيين معلم (اختياري)',
        prefixIcon: Icon(AppIcons.teacher),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('— لا تعيين —')),
        ...widget.teachers.map((t) => DropdownMenuItem(
              value: t['id'],
              child: Text('${t['name'] ?? ''} (${t['email'] ?? ''})'),
            )),
      ],
      onChanged: (v) => setState(() => _selectedTeacherId = v),
    );
  }

  Widget _buildTeacherHint(JisrColors c) {
    return Text(
      _sendToMinistry
          ? 'سيتم إشعار المعلم بعد موافقة الوزارة'
          : 'سيتم إشعار المعلم فوراً (بدون انتظار)',
      style: TextStyle(fontSize: 12, color: c.muted),
    );
  }

  Widget _buildErrorBox() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.red, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
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
              backgroundColor:
                  _sendToMinistry ? AppColors.brandBlueLight : AppColors.brandTealDeep,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(_sendToMinistry ? AppIcons.upload : AppIcons.send),
            label: Text(
              _loading
                  ? 'جارٍ الإرسال...'
                  : _sendToMinistry
                      ? 'إرسال للوزارة'
                      : 'إرسال للمعلمين',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _loading ? null : _submit,
          ),
        ),
      ],
    );
  }
}