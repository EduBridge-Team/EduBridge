part of 'add_lesson_sheet.dart';

extension _AddLessonWidgets on _AddLessonSheetState {
  Widget _buildHeader() {
    if (widget.fullScreen) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(AppIcons.lesson, color: AppColors.brandBlue, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.lessonCreateTitle,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(AppIcons.close),
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget _buildForParentsToggle(JisrColors c) {
    return Container(
      decoration: BoxDecoration(
        color: _forParents
            ? AppColors.brandTealDeep.withValues(alpha: 0.1)
            : c.tintTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _forParents ? AppColors.brandTeal : c.line,
          width: _forParents ? 2 : 1.5,
        ),
      ),
      child: Material(type: MaterialType.transparency, child: SwitchListTile(
        value: _forParents,
        activeThumbColor: AppColors.brandTealDeep,
        onChanged: (v) => _updateLessonSheetState(() => _forParents = v),
        title: Row(
          children: [
            const Icon(
              AppIcons.parent,
              color: AppColors.brandTealDeep,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              context.l10n.lessonForParents,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            )),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsetsDirectional.only(top: 4, start: 30),
          child: Text(
            _forParents
                ? context.l10n.lessonParentsOnlyHint
                : context.l10n.lessonParentsToggleHint,
            style: TextStyle(fontSize: 12, color: c.muted, height: 1.4),
          ),
        ),
      )),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.error, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(switch (_error!) {
              _LessonError.titleRequired => context.l10n.lessonTitleRequired,
              _LessonError.studentsRequired => context.l10n.homeworkChooseStudent,
              _LessonError.saveFailed => context.l10n.lessonSaveFailed,
              _LessonError.connectionFailed => context.l10n.connectionFailed,
            }, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _forParents ? AppColors.brandTealDeep : AppColors.brandBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
      ),
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(AppIcons.save),
      onPressed: _saving ? null : _save,
      label: Text(
        _saving ? context.l10n.saving : context.l10n.lessonSave,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildActions() {
    if (widget.fullScreen) {
      return SizedBox(
        width: double.infinity,
        child: _buildSaveButton(),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
            child: Text(context.l10n.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildSaveButton()),
      ],
    );
  }
}
