part of 'choose_specialty_screen.dart';

extension _ChooseSpecialtyScreenStateView on _ChooseSpecialtyScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.specialtyTitle),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.warning,
                    color: AppColors.orangeDeep,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.specialtyMissing,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.orangeDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.specialtyRequiredHint,
                          style: textTheme.bodySmall?.copyWith(
                            color: c.onTint,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.specialtyChooseHeading,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 16),
            _SpecialtyCard(
              icon: AppIcons.specialist,
              title: context.l10n.learningSupportSpecialist,
              description:
                  context.l10n.specialtyLearningSupportHint,
              color: AppColors.purple,
              selected: _selected == 'learning_support',
              onTap: () => _refreshState(() => _selected = 'learning_support'),
            ),
            const SizedBox(height: 12),
            _SpecialtyCard(
              icon: AppIcons.lesson,
              title: context.l10n.educationalSpecialist,
              description:
                  context.l10n.specialtyEducationalHint,
              color: AppColors.brandBlue,
              selected: _selected == 'educational',
              onTap: () => _refreshState(() => _selected = 'educational'),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error, color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        switch (_error!) {
                          _SpecialtyError.selection => context.l10n.specialtyChooseRequired,
                          _SpecialtyError.save => context.l10n.specialtySaveFailed,
                          _SpecialtyError.connection => context.l10n.connectionFailed,
                        },
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected == null
                      ? Colors.grey
                      : (_selected == 'learning_support'
                          ? AppColors.purple
                          : AppColors.brandBlue),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(AppIcons.check),
                label: Text(_saving ? context.l10n.savingGrade : context.l10n.specialtyConfirm),
                onPressed: _selected == null || _saving ? null : _save,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.specialtyChangeHint,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: c.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
