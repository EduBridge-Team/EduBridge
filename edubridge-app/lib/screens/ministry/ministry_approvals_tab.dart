// lib/screens/ministry/ministry_approvals_tab.dart
part of 'ministry_screen.dart';

class _MinistryApprovalsTab extends StatefulWidget {
  const _MinistryApprovalsTab();

  @override
  State<_MinistryApprovalsTab> createState() => _MinistryApprovalsTabState();
}

class _MinistryApprovalsTabState extends State<_MinistryApprovalsTab> {
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _processed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final serverPending = await ApiService.getPendingApprovals();
      final serverProcessed =
          await ApiService.getAllApprovals(status: 'approved,rejected');

      if (serverPending.isEmpty) {
        final localPending = await ApprovalService.getPendingApprovals();
        final localApproved = await ApprovalService.getApprovedPlans();
        final localRejected = await ApprovalService.getRejectedPlans();

        setState(() {
          _pending = localPending;
          _processed = [...localApproved, ...localRejected];
          _loading = false;
        });
      } else {
        setState(() {
          _pending = serverPending.cast<Map<String, dynamic>>();
          _processed = serverProcessed.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleApprove(Map approval) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(AppIcons.check, color: AppColors.brandTealDeep, size: 32),
            SizedBox(width: 8),
            Text('اعتماد الخطة'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من اعتماد خطة الطفل "${approval['child_name']}"؟\n\n'
          'سيتم إشعار المختص والمعلم.',
          style: const TextStyle(fontSize: 15, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTealDeep),
            icon: const Icon(AppIcons.check),
            label: const Text('اعتماد'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApprovalService.approve(
      approvalId: approval['id'].toString(),
      specialistName: 'الوزارة',
    );

    final serverId = approval['server_id'] ?? approval['id'];
    await ApiService.approveMinistryRequest(
      serverId is int ? serverId : int.tryParse(serverId.toString()) ?? 0,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم اعتماد الخطة وإشعار المختص والمعلم'),
        backgroundColor: AppColors.brandTealDeep,
      ),
    );
    _load();
  }

  Future<void> _handleReject(Map approval) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(AppIcons.error, color: AppColors.red, size: 32),
            SizedBox(width: 8),
            Text('رفض الخطة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رفض خطة الطفل "${approval['child_name']}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                hintText: 'مثال: تحتاج مراجعة أهداف الخطة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            icon: const Icon(AppIcons.close),
            label: const Text('رفض'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApprovalService.reject(
      approvalId: approval['id'].toString(),
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );

    final serverId = approval['server_id'] ?? approval['id'];
    await ApiService.rejectMinistryRequest(
      serverId is int ? serverId : int.tryParse(serverId.toString()) ?? 0,
      reason: reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم رفض الخطة وإشعار المختص'),
        backgroundColor: AppColors.red,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _MinistrySectionHeader(
            title: 'طلبات بانتظار المراجعة',
            count: '${_pending.length}',
            color: AppColors.orange,
          ),
          if (_pending.isEmpty)
            _MinistryEmptyCard(
              message: 'لا توجد طلبات معلّقة حالياً',
              icon: Icons.inbox_outlined,
            )
          else
            ..._pending.map((a) => _MinistryApprovalCard(
                  approval: a,
                  onApprove: () => _handleApprove(a),
                  onReject: () => _handleReject(a),
                )),

          const SizedBox(height: 24),

          if (_processed.isNotEmpty) ...[
            _MinistrySectionHeader(
              title: 'سجل القرارات',
              count: '${_processed.length}',
              color: AppColors.brandTeal,
            ),
            ..._processed.take(20).map((a) => _MinistryProcessedCard(approval: a)),
          ],
        ],
      ),
    );
  }
}

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
                  backgroundColor: AppColors.brandTealDeep,
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
                    color: AppColors.brandTealDeep.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.clock, size: 12, color: AppColors.brandTealDeep),
                      SizedBox(width: 4),
                      Text('قيد المراجعة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandTealDeep,
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
    final color = isApproved ? AppColors.brandTealDeep : AppColors.red;

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