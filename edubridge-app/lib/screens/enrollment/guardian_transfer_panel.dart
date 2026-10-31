import 'package:flutter/material.dart';
import '../../services/enrollment/enrollment_api_client.dart';

class GuardianTransferPanel extends StatefulWidget {
  const GuardianTransferPanel({super.key, required this.childId});
  final int childId;
  @override
  State<GuardianTransferPanel> createState() => _GuardianTransferPanelState();
}

class _GuardianTransferPanelState extends State<GuardianTransferPanel> {
  final _client = EnrollmentApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _busy = false;
  bool _opened = false;
  String? _error;

  @override
  void didUpdateWidget(covariant GuardianTransferPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _items = [];
      _opened = false;
      _error = null;
    }
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() { _opened = true; _busy = true; _error = null; });
    try {
      final data = await _client.get('/parent/children/${widget.childId}/transfers');
      final raw = data['requests'];
      if (raw is! List) throw const FormatException('Invalid transfer list');
      final items = raw.map((value) {
        if (value is! Map) throw const FormatException('Invalid transfer');
        final item = Map<String, dynamic>.from(value);
        if (item['child_id'] != widget.childId || item['id'] is! int ||
            item['version'] is! int || item['status'] is! String) {
          throw const FormatException('Transfer scope mismatch');
        }
        return item;
      }).toList();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل طلبات النقل / Unable to load transfers');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(Map<String, dynamic> item, bool approve) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'الموافقة على النقل / Approve transfer' : 'رفض النقل / Reject transfer'),
        content: const Text('سيتم تسجيل قرار ولي الأمر. الموافقة لا تُكمل النقل دون قبول المدرسة المستقبلة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء / Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد / Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _client.post(
        '/parent/children/${widget.childId}/transfers/${item['id']}/decision',
        {'decision': approve ? 'approve' : 'reject', 'version': item['version']},
        success: 200,
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تسجيل القرار / Unable to save decision');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('طلبات نقل المدرسة / School transfer requests'),
      OutlinedButton.icon(onPressed: _busy ? null : _load, icon: Icon(_opened ? Icons.refresh : Icons.swap_horiz),
        label: Text(_opened ? 'تحديث / Refresh' : 'عرض طلبات النقل / View transfers')),
      if (_opened && _busy) const LinearProgressIndicator(),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (_opened && !_busy && _error == null && _items.isEmpty) const Text('لا توجد طلبات نقل / No transfer requests'),
      for (final item in _items) Card(child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('طلب #${item['id']} — ${item['status']}'),
          Text('من مدرسة #${item['source_school_id']} إلى مدرسة #${item['destination_school_id']}'),
          if (item['status'] == 'pending_guardian') ...[
            FilledButton(onPressed: _busy ? null : () => _decide(item, true),
              child: const Text('موافقة / Approve')),
            OutlinedButton(onPressed: _busy ? null : () => _decide(item, false),
              child: const Text('رفض / Reject')),
          ],
        ]),
      )),
    ],
  );
}
