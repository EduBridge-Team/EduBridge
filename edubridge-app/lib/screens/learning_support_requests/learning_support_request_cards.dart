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
              _buildHeader(request, statusColor, c),
              const SizedBox(height: 10),
              _buildReasonRow(request, c),
              if (request.isScheduled && request.scheduledAt != null) ...[
                const SizedBox(height: 8),
                _buildScheduleInfo(request, c),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      LearningSupportRequest request, Color statusColor, JisrColors c) {
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
                  Text(
                    request.parentName,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            request.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonRow(LearningSupportRequest request, JisrColors c) {
    return Row(
      children: [
        Text(request.urgencyLabel, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'السبب: ${request.reason}',
            style: TextStyle(fontSize: 13, color: c.body),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(LearningSupportRequest request, JisrColors c) {
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
          Text(
            'الموعد: ${s.day}/${s.month} '
            '${s.hour}:${s.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 12, color: c.onTint),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BottomSheet جدولة الاجتماع
// ═══════════════════════════════════════════════════════════
