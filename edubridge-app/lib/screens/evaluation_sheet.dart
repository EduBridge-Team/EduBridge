// نموذج تقييم الطفل - للمختص
// ✅ محدّث: خيار إرسال للوزارة + إشعار تلقائي للمعلم في المسار السريع
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/approval_service.dart';
import '../theme.dart';
import '../utils/safe_bottom.dart';

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

  // ✅ جديد: هل تُرسل الخطة للوزارة؟
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

  // ═══════════════════════════════════════════════════════════
  //  الإرسال
  // ═══════════════════════════════════════════════════════════
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

      // ═══════════════════════════════════════════════════════
      //  تحديث الطفل محلياً
      // ═══════════════════════════════════════════════════════
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

      // ═══════════════════════════════════════════════════════
      //  ✅ القرار حسب خيار "إرسال للوزارة"
      // ═══════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  //  المسار 1: إرسال للوزارة
  // ✅ مُصلَّح: Map<String, dynamic> بدل Map
  // ═══════════════════════════════════════════════════════════
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
      icon: Icons.how_to_reg,
      iconColor: AppColors.orange,
      title: '📤 تم الإرسال للوزارة',
      message: 'سيتم مراجعة الخطة من الوزارة.\n\n'
          '• عند الموافقة: يُشعَر المعلم والمعلمون المعنيون\n'
          '• عند الرفض: تعود إليك الخطة للتعديل',
    );

    if (mounted) Navigator.pop(context, true);
  }

  // ═══════════════════════════════════════════════════════════
  //  المسار 2: إرسال للمعلمين مباشرة
  // ✅ مُصلَّح: Map<String, dynamic> بدل Map
  // ═══════════════════════════════════════════════════════════
  Future<void> _handleDirectToTeacherFlow(
    Map<String, dynamic> result,
  ) async {
    // ─── إرسال إشعار للمعلم المعيّن ───
    if (_selectedTeacherId != null) {
      try {
        await ApiService.authPost('/notifications/send', {
          'user_id': _selectedTeacherId,
          'child_id': widget.child['id'],
          'evaluation_id': result['id'],
          'title': '📋 تقييم جديد للطفل',
          'body':
              'رفع المختص تقييماً للطفل "${widget.child['name']}" — راجع الخطة وابدأ التنفيذ',
          'type': 'evaluation_created',
        });
      } catch (_) {
        // لا نوقف العملية لو فشل الإشعار — التقييم محفوظ
        debugPrint('⚠️ فشل إرسال إشعار للمعلم');
      }
    }

    if (!mounted) return;

    _showSuccessDialog(
      icon: Icons.check_circle,
      iconColor: AppColors.green,
      title: '✅ تم التقييم بنجاح',
      message: _selectedTeacherId != null
          ? 'تم إرسال التقييم للمعلم المسؤول لبدء التنفيذ مباشرة.'
          : 'تم حفظ التقييم. يمكن تعيين معلم لاحقاً.',
    );

    if (mounted) Navigator.pop(context, true);
  }

  // ═══════════════════════════════════════════════════════════
  //  نافذة نجاح موحّدة
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  //  الواجهة الرئيسية
  // ═══════════════════════════════════════════════════════════
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
                // ─── العنوان ───
                Row(
                  children: [
                    const Icon(Icons.assessment,
                        color: Color.fromARGB(255, 20, 156, 219)),
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
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ─── تنبيه ───
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.tintOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.orangeDeep, size: 22),
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
                ),
                const SizedBox(height: 16),

                // ─── نوع التقييم ───
                DropdownButtonFormField<String>(
                  initialValue: _evaluationType,
                  decoration: const InputDecoration(
                    labelText: 'نوع التقييم *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'initial', child: Text('تقييم أولي')),
                    DropdownMenuItem(
                        value: 'follow_up', child: Text('متابعة')),
                    DropdownMenuItem(
                        value: 'final', child: Text('تقييم نهائي')),
                  ],
                  onChanged: (v) =>
                      setState(() => _evaluationType = v ?? 'initial'),
                ),
                const SizedBox(height: 16),

                // ─── التقييمات ───
                TextFormField(
                  controller: _cognitiveCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التقييم المعرفي *',
                    prefixIcon: Icon(Icons.grain),
                    hintText: 'مستوى التفكير، الانتباه، الذاكرة، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'هذا الحقل مطلوب'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _motorCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التقييم الحركي *',
                    prefixIcon: Icon(Icons.fitness_center),
                    hintText: 'المهارات الحركية الدقيقة والخشنة، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'هذا الحقل مطلوب'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emotionalCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التفاعل أثناء التعلم *',
                    prefixIcon: Icon(Icons.mood),
                    hintText: 'التفاعل مع الأنشطة، الاستجابة للتوجيه، المشاركة، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'هذا الحقل مطلوب'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _socialCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التقييم الاجتماعي *',
                    prefixIcon: Icon(Icons.people),
                    hintText: 'التفاعل مع الآخرين، المهارات الاجتماعية، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'هذا الحقل مطلوب'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _recommendationsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'التوصيات *',
                    prefixIcon: Icon(Icons.lightbulb),
                    hintText: 'توصيات للمعلم وولي الأمر، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'هذا الحقل مطلوب'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _educationalPlanCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الخطة التعليمية *',
                    prefixIcon: Icon(Icons.school),
                    hintText: 'الخطة الدراسية المقترحة، ...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'هذا الحقل مطلوب'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _teachingMethodsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'طرق التدريس (اختياري)',
                    prefixIcon: Icon(Icons.functions),
                    hintText: 'أدخل الطرق مفصولة بفواصل، مثال: بصري، سمعي،...',
                  ),
                ),
                const SizedBox(height: 16),

                // ─── تعيين معلم ───
                DropdownButtonFormField<int?>(
                  initialValue: _selectedTeacherId,
                  decoration: const InputDecoration(
                    labelText: 'تعيين معلم (اختياري)',
                    prefixIcon: Icon(Icons.person_add),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('— لا تعيين —')),
                    ...widget.teachers.map((t) => DropdownMenuItem(
                          value: t['id'],
                          child:
                              Text('${t['name'] ?? ''} (${t['email'] ?? ''})'),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedTeacherId = v),
                ),
                const SizedBox(height: 8),
                Text(
                  _sendToMinistry
                      ? 'سيتم إشعار المعلم بعد موافقة الوزارة'
                      : 'سيتم إشعار المعلم فوراً (بدون انتظار)',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
                const SizedBox(height: 16),

                // ═════════════════════════════════════════════════
                //  ✅ بطاقة "إرسال للوزارة"
                // ═════════════════════════════════════════════════
                _buildMinistryToggleCard(c),

                // ─── خطأ ───
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ─── الأزرار ───
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
                          backgroundColor: _sendToMinistry
                              ? AppColors.orange
                              : AppColors.green,
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
                            : Icon(_sendToMinistry
                                ? Icons.how_to_reg
                                : Icons.send),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  بطاقة "إرسال للوزارة"
  // ═══════════════════════════════════════════════════════════
  Widget _buildMinistryToggleCard(JisrColors c) {
    final active = _sendToMinistry;

    return InkWell(
      onTap: () => setState(() => _sendToMinistry = !_sendToMinistry),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active
              ? AppColors.orange.withValues(alpha: 0.08)
              : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.orange : c.line,
            width: active ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ─── أيقونة دائرية ───
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.orange
                        : c.muted.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active
                          ? AppColors.orangeDeep
                          : c.muted.withValues(alpha: 0.5),
                      width: 2.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    active ? Icons.how_to_reg : Icons.upload_file,
                    color: active ? Colors.white : c.muted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إرسال الخطة للوزارة للموافقة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                              active ? AppColors.orangeDeep : c.heading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        active
                            ? 'سيتم مراجعة الخطة من الوزارة'
                            : 'لن تُرسل للوزارة — تُرسل للمعلم مباشرة',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _sendToMinistry,
                  activeThumbColor: AppColors.orange,
                  inactiveThumbColor: c.muted,
                  onChanged: (v) =>
                      setState(() => _sendToMinistry = v),
                ),
              ],
            ),

            // ─── تفاصيل عند التفعيل ───
            if (active) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ministryStep(
                      Icons.check_circle,
                      AppColors.green,
                      'عند الموافقة: يُشعَر المعلم والمختص',
                    ),
                    const SizedBox(height: 8),
                    _ministryStep(
                      Icons.cancel,
                      AppColors.red,
                      'عند الرفض: تعود إليك الخطة للتعديل',
                    ),
                    const SizedBox(height: 8),
                    _ministryStep(
                      Icons.schedule,
                      AppColors.orange,
                      'قد يستغرق الرد من 24 إلى 48 ساعة',
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.flash_on,
                      color: AppColors.tealDeep,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المسار السريع',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: c.onTint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'التقييم يُرسل مباشرة للمعلم لبدء التنفيذ بدون انتظار، ويُشعَر المعلم فوراً.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: c.onTint,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ministryStep(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}