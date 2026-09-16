// lib/screens/therapy_requests_screen.dart
import 'package:flutter/material.dart';
import '../model/therapy_request_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

class TherapyRequestsScreen extends StatefulWidget {
  const TherapyRequestsScreen({super.key});

  @override
  State<TherapyRequestsScreen> createState() =>
      _TherapyRequestsScreenState();
}

class _TherapyRequestsScreenState extends State<TherapyRequestsScreen> {
  List<TherapyRequest> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService.getTherapyRequests();
      if (!mounted) return;
      setState(() {
        _requests = raw
            .map((e) => TherapyRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الطلبات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: '🧠 طلبات الدعم النفسي'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _requests.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final c = JisrColors.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.inbox, size: 80, color: c.muted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'لا توجد طلبات حالياً',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: c.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final pending =
        _requests.where((r) => r.isPending).toList();
    final scheduled =
        _requests.where((r) => r.isScheduled).toList();
    final done = _requests
        .where((r) =>
            r.status == TherapyRequestStatus.completed ||
            r.status == TherapyRequestStatus.cancelled)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionHeader('⏳ قيد المراجعة', pending.length,
              AppColors.orange),
          ...pending.map((r) => _RequestCard(
                request: r,
                onTap: () => _openScheduleSheet(r),
              )),
          const SizedBox(height: 16),
        ],
        if (scheduled.isNotEmpty) ...[
          _sectionHeader('📅 جلسات مجدولة', scheduled.length,
              AppColors.teal),
          ...scheduled.map((r) => _RequestCard(
                request: r,
                onTap: () => _openScheduleSheet(r),
              )),
          const SizedBox(height: 16),
        ],
        if (done.isNotEmpty) ...[
          _sectionHeader('✅ منتهية', done.length, AppColors.green),
          ...done.map((r) => _RequestCard(request: r, onTap: null)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
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

  // ✅ BottomSheet لتحديد الموعد
  Future<void> _openScheduleSheet(TherapyRequest request) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleTherapySheet(request: request),
    );
    if (result == true) _load();
  }
}

// ═══════════════════════════════════════════════════════════
//  بطاقة طلب
// ═══════════════════════════════════════════════════════════
class _RequestCard extends StatelessWidget {
  final TherapyRequest request;
  final VoidCallback? onTap;

  const _RequestCard({required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    Color statusColor;
    switch (request.status) {
      case TherapyRequestStatus.pending:
        statusColor = AppColors.orange;
        break;
      case TherapyRequestStatus.scheduled:
        statusColor = AppColors.teal;
        break;
      case TherapyRequestStatus.completed:
        statusColor = AppColors.green;
        break;
      case TherapyRequestStatus.cancelled:
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.pink,
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
                        Text(
                          'من: ${request.parentName}',
                          style: TextStyle(
                              fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    request.urgencyLabel,
                    style: const TextStyle(fontSize: 13),
                  ),
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
              ),
              if (request.isScheduled &&
                  request.scheduledAt != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.tintTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event,
                          size: 16, color: AppColors.tealDeep),
                      const SizedBox(width: 6),
                      Text(
                        'الموعد: ${request.scheduledAt!.day}/${request.scheduledAt!.month} '
                        '${request.scheduledAt!.hour}:${request.scheduledAt!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 12, color: c.onTint),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BottomSheet: تحديد الموعد + الرابط
// ═══════════════════════════════════════════════════════════
class _ScheduleTherapySheet extends StatefulWidget {
  final TherapyRequest request;

  const _ScheduleTherapySheet({required this.request});

  @override
  State<_ScheduleTherapySheet> createState() =>
      _ScheduleTherapySheetState();
}

class _ScheduleTherapySheetState extends State<_ScheduleTherapySheet> {
  DateTime? _scheduledAt;
  TimeOfDay? _time;
  final _meetingLinkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _meetingLinkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _scheduledAt = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_scheduledAt == null || _time == null) {
      setState(() => _error = 'اختر التاريخ والوقت');
      return;
    }
    if (_meetingLinkCtrl.text.trim().isEmpty) {
      setState(() => _error = 'رابط الجلسة مطلوب');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final scheduled = DateTime(
        _scheduledAt!.year,
        _scheduledAt!.month,
        _scheduledAt!.day,
        _time!.hour,
        _time!.minute,
      );

      final ok = await ApiService.scheduleTherapyRequest(
        requestId: widget.request.id,
        scheduledAt: scheduled,
        meetingLink: _meetingLinkCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديد الموعد وإرسال الرابط لولي الأمر'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = 'فشل حفظ الموعد';
          _saving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final isScheduled = widget.request.isScheduled;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── العنوان ───
              Row(
                children: [
                  const Icon(Icons.psychology,
                      color: AppColors.pink, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'طلب جلسة — ${widget.request.childName}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── تفاصيل الطلب ───
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.request.urgencyLabel,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          widget.request.reason,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tealDeep),
                        ),
                      ],
                    ),
                    if (widget.request.description != null &&
                        widget.request.description!.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text(
                        widget.request.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: c.onTint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── التاريخ والوقت ───
              if (isScheduled && widget.request.scheduledAt != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available,
                          color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'مجدولة: ${widget.request.scheduledAt!.day}/${widget.request.scheduledAt!.month} '
                          '${widget.request.scheduledAt!.hour}:${widget.request.scheduledAt!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                isScheduled ? 'تعديل الموعد:' : 'حدّد الموعد:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _pickerTile(
                      icon: Icons.calendar_today,
                      label: _scheduledAt == null
                          ? 'اختر التاريخ'
                          : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}',
                      onTap: _pickDate,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pickerTile(
                      icon: Icons.access_time,
                      label: _time == null
                          ? 'اختر الوقت'
                          : _time!.format(context),
                      onTap: _pickTime,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── رابط الـ Meeting ───
              TextField(
                controller: _meetingLinkCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط الجلسة (Zoom / Google Meet) *',
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://meet.google.com/...',
                ),
              ),
              const SizedBox(height: 12),

              // ─── ملاحظات ───
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات لولي الأمر (اختياري)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
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
                          : const Icon(Icons.check),
                      label: Text(
                        _saving
                            ? '...'
                            : isScheduled
                                ? 'تعديل'
                                : 'تأكيد',
                      ),
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    final c = JisrColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.heading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}