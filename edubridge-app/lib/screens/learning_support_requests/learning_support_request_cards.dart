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
class ScheduleLearningSupportSheet extends StatefulWidget {
  final LearningSupportRequest request;

  const ScheduleLearningSupportSheet({super.key, required this.request});

  @override
  State<ScheduleLearningSupportSheet> createState() =>
      _ScheduleLearningSupportSheetState();
}

class _ScheduleLearningSupportSheetState
    extends State<ScheduleLearningSupportSheet> {
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
      setState(() => _error = 'رابط الاجتماع مطلوب');
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

      final ok = await ApiService.scheduleLearningSupportRequest(
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
            content: Text('تم تحديد الموعد وإرسال الرابط لولي الأمر'),
            backgroundColor: AppColors.green,
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
              _buildHeader(c),
              const SizedBox(height: 12),
              _buildRequestInfo(c),
              const SizedBox(height: 20),
              if (isScheduled && widget.request.scheduledAt != null) ...[
                _buildCurrentSchedule(c),
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
              _buildDatePickerRow(context, c),
              const SizedBox(height: 16),
              _buildMeetingLinkField(),
              const SizedBox(height: 12),
              _buildNotesField(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.red)),
              ],
              const SizedBox(height: 20),
              _buildActions(isScheduled: isScheduled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(JisrColors c) {
    return Row(
      children: [
        const Icon(AppIcons.specialist, color: AppColors.purple, size: 32),
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
          icon: const Icon(AppIcons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildRequestInfo(JisrColors c) {
    return Container(
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
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                widget.request.reason,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandBlue),
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
    );
  }

  Widget _buildCurrentSchedule(JisrColors c) {
    final s = widget.request.scheduledAt!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.event, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'مجدولة: ${s.day}/${s.month} '
              '${s.hour}:${s.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow(BuildContext context, JisrColors c) {
    return Row(
      children: [
        Expanded(
          child: _pickerTile(
            icon: AppIcons.calendar,
            label: _scheduledAt == null
                ? 'اختر التاريخ'
                : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}',
            onTap: _pickDate,
            color: AppColors.brandBlue,
            c: c,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _pickerTile(
            icon: AppIcons.clock,
            label: _time == null ? 'اختر الوقت' : _time!.format(context),
            onTap: _pickTime,
            color: AppColors.orange,
            c: c,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingLinkField() {
    return TextField(
      controller: _meetingLinkCtrl,
      decoration: const InputDecoration(
        labelText: 'رابط الاجتماع (Zoom / Google Meet) *',
        prefixIcon: Icon(Icons.link),
        hintText: 'https://meet.google.com/...',
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'ملاحظات لولي الأمر (اختياري)',
        prefixIcon: Icon(AppIcons.edit),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildActions({required bool isScheduled}) {
    return Row(
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
                : const Icon(AppIcons.check),
            label: Text(
              _saving ? '...' : isScheduled ? 'تعديل' : 'تأكيد',
            ),
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required JisrColors c,
  }) {
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