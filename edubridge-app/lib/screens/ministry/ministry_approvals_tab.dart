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
            Icon(AppIcons.check, color: AppColors.green, size: 32),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
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
        backgroundColor: AppColors.green,
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
