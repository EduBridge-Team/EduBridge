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
            context.l10n.evaluationForChild(childName),
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
          const Icon(AppIcons.info, color: AppColors.brandBlueDeep, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.evaluationRoutingNotice,
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
      isExpanded: true,
      itemHeight: null,
      initialValue: _evaluationType,
      decoration: InputDecoration(
        labelText: context.l10n.requiredFieldLabel(context.l10n.evaluationType),
        prefixIcon: Icon(AppIcons.filter),
      ),
      items: [
        DropdownMenuItem(value: 'initial', child: Text(context.l10n.initialEvaluation, maxLines: 1, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'follow_up', child: Text(context.l10n.followUpEvaluation, maxLines: 1, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'final', child: Text(context.l10n.finalEvaluation, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) => _refreshState(() => _evaluationType = v ?? 'initial'),
    );
  }

  Widget _buildCognitiveField() {
    return TextFormField(
      controller: _cognitiveCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.requiredFieldLabel(context.l10n.cognitiveAssessment),
        prefixIcon: Icon(AppIcons.cognitive),
        hintText: context.l10n.cognitiveAssessmentHint,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null,
    );
  }

  Widget _buildMotorField() {
    return TextFormField(
      controller: _motorCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.requiredFieldLabel(context.l10n.motorAssessment),
        prefixIcon: Icon(AppIcons.motor),
        hintText: context.l10n.motorAssessmentHint,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null,
    );
  }

  Widget _buildEmotionalField() {
    return TextFormField(
      controller: _emotionalCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.requiredFieldLabel(context.l10n.learningInteraction),
        prefixIcon: Icon(AppIcons.speech),
        hintText: context.l10n.learningInteractionHint,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null,
    );
  }

  Widget _buildSocialField() {
    return TextFormField(
      controller: _socialCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.requiredFieldLabel(context.l10n.socialAssessment),
        prefixIcon: Icon(AppIcons.users),
        hintText: context.l10n.socialAssessmentHint,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null,
    );
  }

  Widget _buildRecommendationsField() {
    return TextFormField(
      controller: _recommendationsCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.requiredFieldLabel(context.l10n.recommendations),
        prefixIcon: Icon(AppIcons.info),
        hintText: context.l10n.recommendationsHint,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null,
    );
  }

  Widget _buildEducationalPlanField() {
    return TextFormField(
      controller: _educationalPlanCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.requiredFieldLabel(context.l10n.educationalPlan),
        prefixIcon: Icon(AppIcons.plan),
        hintText: context.l10n.educationalPlanHint,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null,
    );
  }

  Widget _buildTeachingMethodsField() {
    return TextFormField(
      controller: _teachingMethodsCtrl,
      decoration: InputDecoration(
        labelText: context.l10n.teachingMethodsOptional,
        prefixIcon: Icon(AppIcons.lesson),
        hintText: context.l10n.teachingMethodsHint,
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return DropdownButtonFormField<int?>(
      isExpanded: true,
      itemHeight: null,
      initialValue: _selectedTeacherId,
      decoration: InputDecoration(
        labelText: context.l10n.assignTeacherOptional,
        prefixIcon: Icon(AppIcons.teacher),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(context.l10n.noTeacherAssignment, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ...widget.teachers.map((t) => DropdownMenuItem(
              value: t['id'],
              child: Text('${t['name'] ?? ''} (${t['email'] ?? ''})', maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => _refreshState(() => _selectedTeacherId = v),
    );
  }

  Widget _buildTeacherHint(JisrColors c) {
    return Text(
      _sendToMinistry
          ? context.l10n.teacherNotifiedAfterApproval
          : context.l10n.teacherNotifiedImmediately,
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
          context.sharedMessage(_error),
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
            child: Text(context.l10n.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _sendToMinistry ? AppColors.blue : AppColors.brandTealDeep,
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
                  ? context.l10n.sendingAlt
                  : _sendToMinistry
                      ? context.l10n.sendToMinistry
                      : context.l10n.sendToTeachers,
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
