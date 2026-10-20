// lib/screens/learning_support_requests/learning_support_request_cards.dart
part of 'learning_support_requests_screen.dart';

// ═══════════════════════════════════════════════════════════
//  بطاقة الطلب
// ═══════════════════════════════════════════════════════════
class LearningSupportRequestCard extends StatelessWidget {
  final LearningSupportRequest request;
  final VoidCallback? onTap;

  const LearningSupportRequestCard({
    super.key,
    required this.request,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    Color statusColor;
    switch (request.status) {
      case LearningSupportRequestStatus.pending:
        statusColor = AppColors.orange;
        break;
      case LearningSupportRequestStatus.scheduled:
        statusColor = AppColors.brandTeal;
        break;
      case LearningSupportRequestStatus.completed:
        statusColor = AppColors.green;
        break;
      case LearningSupportRequestStatus.cancelled:
        statusColor = AppColors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, request, statusColor, c),
              const SizedBox(height: 10),
              _buildReasonRow(context, request, c),
              if (request.isScheduled && request.scheduledAt != null) ...[
                const SizedBox(height: 8),
                _buildScheduleInfo(context, request, c),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, LearningSupportRequest request, Color statusColor, JisrColors c) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.brandBlue,
          child: Text(
            request.childName.isNotEmpty
                ? request.childName.characters.first
                : '؟',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.childName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              Row(
                children: [
                  Icon(AppIcons.parent, size: 12, color: c.muted),
                  const SizedBox(width: 4),
                  Expanded(child: Text(
                    request.parentName,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  )),
                ],
              ),
            ],
          ),
        ),
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            LearningSupportPresentation.requestStatus(request.status, context.l10n),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildReasonRow(BuildContext context, LearningSupportRequest request, JisrColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LearningSupportPresentation.urgency(request.urgency, context.l10n),
            style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Text(context.l10n.supportReasonLabel(
          LearningSupportPresentation.reason(request.reason, context.l10n)),
          style: TextStyle(fontSize: 13, color: c.body)),
      ],
    );
  }

  Widget _buildScheduleInfo(BuildContext context, LearningSupportRequest request, JisrColors c) {
    final s = request.scheduledAt!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.tintTeal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.event, size: 16, color: AppColors.brandBlue),
          const SizedBox(width: 6),
          Expanded(child: Text(
            context.l10n.supportAppointmentDate(LearningSupportPresentation.date(s, context.l10n)),
            style: TextStyle(fontSize: 12, color: c.onTint),
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BottomSheet جدولة الاجتماع
// ═══════════════════════════════════════════════════════════
