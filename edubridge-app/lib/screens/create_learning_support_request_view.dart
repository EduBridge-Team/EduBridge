part of 'create_learning_support_request_screen.dart';

extension _CreateLearningSupportRequestScreenStateView on _CreateLearningSupportRequestScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.requestLearningSupport),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.specialist,
                      color: AppColors.brandBlue, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.requestLearningSupport,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                        Text(
                          context.l10n.supportChildIntro(widget.childName),
                          style: TextStyle(fontSize: 13, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              context.l10n.supportReasonField,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  itemHeight: null,
                  hint: Text(context.l10n.supportReasonHint),
                  items: _CreateLearningSupportRequestScreenState._reasons
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(LearningSupportPresentation.reason(r, context.l10n))))
                      .toList(),
                  onChanged: (v) => _refreshState(() => _selectedReason = v),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              context.l10n.supportDescriptionHeading,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    context.l10n.supportDescriptionHint,
                alignLabelWithHint: true,
                prefixIcon: Icon(AppIcons.edit),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.l10n.supportDescriptionRequired;
                }
                if (v.trim().length < 20) {
                  return context.l10n.supportDescriptionMinimum;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            Text(
              context.l10n.supportPriorityHeading,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _UrgencyChip(
                    label: context.l10n.supportPriorityLow,
                    selected: _urgency == 'low',
                    color: AppColors.green,
                    onTap: () => _refreshState(() => _urgency = 'low'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _UrgencyChip(
                    label: context.l10n.normalUrgency,
                    selected: _urgency == 'medium',
                    color: AppColors.orange,
                    onTap: () => _refreshState(() => _urgency = 'medium'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _UrgencyChip(
                    label: context.l10n.supportPriorityHigh,
                    selected: _urgency == 'high',
                    color: AppColors.red,
                    onTap: () => _refreshState(() => _urgency = 'high'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.tintYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.info,
                      color: AppColors.orangeDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.supportSchedulingHint,
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                  ),
                ],
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
                child: Row(
                  children: [
                    const Icon(AppIcons.error,
                        color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(LearningSupportPresentation.error(_error!, context.l10n),
                          style: const TextStyle(color: AppColors.red)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(

              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(AppIcons.send),
                label: Text(
                  _saving ? context.l10n.sending : context.l10n.supportSendRequest,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );

  }
}
