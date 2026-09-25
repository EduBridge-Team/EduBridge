part of 'ministry_screen.dart';

class _MinistrySectionHeader extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const _MinistrySectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: c.heading,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinistryEmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _MinistryEmptyCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 60, color: c.muted),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: c.muted, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _MinistryApprovalCard extends StatelessWidget {
  final Map approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _MinistryApprovalCard({
    required this.approval,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.orange,
                  child: Text(
                    (approval['child_name'] ?? '؟').toString().characters.first,
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
                        approval['child_name'] ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        'أُرسل: ${_formatMinistryDate(approval['submitted_at'])}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.clock, size: 12, color: AppColors.orangeDeep),
                      SizedBox(width: 4),
                      Text('قيد المراجعة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orangeDeep,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _miniRow('الخطة التعليمية', approval['educational_plan'], c),
            if (approval['recommendations'] != null)
              _miniRow('التوصيات', approval['recommendations'], c),
            if (approval['teacher_name'] != null)
              _miniRow('المعلم المقترح', approval['teacher_name'], c),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(AppIcons.close),
                    label: const Text('رفض'),
                    onPressed: onReject,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(AppIcons.check),
                    label: const Text('اعتماد'),
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(String label, dynamic value, JisrColors c) {
    if (value == null) return const SizedBox.shrink();
    final text = value.toString();
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.body),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinistryProcessedCard extends StatelessWidget {
  final Map approval;

  const _MinistryProcessedCard({required this.approval});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final status = approval['status'] ?? 'pending';
    final isApproved = status == 'approved';
    final color = isApproved ? AppColors.green : AppColors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isApproved ? AppIcons.check : AppIcons.error,
            color: color,
          ),
        ),
        title: Text(
          approval['child_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${isApproved ? "معتمدة" : "مرفوضة"} • ${_formatMinistryDate(approval['decided_at'] ?? approval['submitted_at'])}',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
      ),
    );
  }
}

String _formatMinistryDate(dynamic value) {
  if (value == null) return '';
  final d = DateTime.tryParse(value.toString());
  if (d == null) return '';
  return '${d.day}/${d.month}/${d.year}';
}