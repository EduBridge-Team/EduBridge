part of 'specialist_suggestions_screen.dart';

extension _SpecialistSuggestionsWidgets on _SpecialistSuggestionsScreenState {
  Widget _buildBody(JisrColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          const Icon(AppIcons.error, size: 54, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            context.sharedMessage(_error),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(AppIcons.refresh),
              label: Text(context.l10n.retryAction),
            ),
          ),
        ],
      );
    }
    if (_suggestions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: c.tintTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.specialist,
                size: 40,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _filter == 'pending'
                ? context.l10n.followupNoPending
                : context.l10n.followupNoSuggestions,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: _suggestions.length,
      itemBuilder: (context, i) =>
          _buildSuggestionCard(_suggestions[i], c),
    );
  }

  Widget _buildSuggestionCard(Map s, JisrColors c) {
    final status = s['status'] ?? 'pending';
    final isLearningSupport = s['specialty'] == 'learning_support';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = AppColors.green;
        statusLabel = context.l10n.followupAcceptedStatus;
        statusIcon = AppIcons.check;
        break;
      case 'rejected':
        statusColor = AppColors.red;
        statusLabel = context.l10n.followupRejectedStatus;
        statusIcon = AppIcons.error;
        break;
      default:
        statusColor = AppColors.orange;
        statusLabel = context.l10n.followupPendingStatus;
        statusIcon = AppIcons.clock;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isLearningSupport
                      ? AppColors.purple
                      : AppColors.brandBlue,
                  child: Text(
                    (s['child_name'] ?? '').toString().trim().characters.firstOrNull ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['child_name'] ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        context.l10n.followupSuggestedBy((s['suggested_by_name'] ?? '').toString()),
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Flexible(child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Flexible(child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      )),
                    ],
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isLearningSupport ? AppColors.purple : AppColors.brandBlue)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isLearningSupport ? AppIcons.specialist : AppIcons.lesson,
                    color: isLearningSupport
                        ? AppColors.brandTealDeep
                        : AppColors.brandBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    isLearningSupport ? context.l10n.learningSupportSpecialist : context.l10n.educationalSpecialist,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isLearningSupport
                          ? AppColors.brandTealDeep
                          : AppColors.brandBlue,
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s['reason'] ?? ''}',
              style: TextStyle(fontSize: 14, height: 1.5, color: c.body),
            ),

            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
                      ),
                      icon: const Icon(AppIcons.close),
                      label: Text(context.l10n.reject),
                      onPressed: () => _reject(s),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: AppColors.green,
                      ),
                      icon: const Icon(AppIcons.check),
                      label: Text(context.l10n.followupAcceptAndFollow),
                      onPressed: () => _accept(s),
                    ),
                ],
              ),
            ],
          ],
        ),
    );
  }
}


/// Owns the draft for the entire dialog route, including its closing animation.
class _FollowupRejectionDialog extends StatefulWidget {
  const _FollowupRejectionDialog({required this.childName});
  final String childName;

  @override
  State<_FollowupRejectionDialog> createState() => _FollowupRejectionDialogState();
}

class _FollowupRejectionDialogState extends State<_FollowupRejectionDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Row(children: [
      const Icon(AppIcons.error, color: AppColors.red, size: 28),
      const SizedBox(width: 8),
      Expanded(child: Text(context.l10n.followupRejectTitle)),
    ]),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.followupRejectChild(widget.childName),
          style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.l10n.followupRejectReasonOptional,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: AppColors.red),
        onPressed: () => Navigator.pop(context, _reasonController.text.trim()),
        child: Text(context.l10n.reject),
      ),
    ],
  );
}
