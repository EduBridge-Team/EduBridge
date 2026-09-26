// Evaluation form presentation helpers.
part of 'evaluation_sheet.dart';

extension _EvaluationFieldsExtension on _EvaluationSheetState {
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
          const Icon(AppIcons.info, color: AppColors.orangeDeep, size: 22),
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
      onChanged: (v) => _refreshState(() => _evaluationType = v ?? 'initial'),
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
      onChanged: (v) => _refreshState(() => _selectedTeacherId = v),
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
                  _sendToMinistry ? AppColors.orange : AppColors.green,
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
