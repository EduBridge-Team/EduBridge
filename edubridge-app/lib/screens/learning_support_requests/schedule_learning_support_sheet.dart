part of 'learning_support_requests_screen.dart';

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
  LearningSupportError? _error;

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
    if (picked != null && mounted) setState(() => _scheduledAt = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_scheduledAt == null || _time == null) {
      setState(() => _error = LearningSupportError.dateTimeRequired);
      return;
    }
    if (_meetingLinkCtrl.text.trim().isEmpty) {
      setState(() => _error = LearningSupportError.linkRequired);
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
        final messenger = ScaffoldMessenger.of(context);
        final message = context.l10n.supportScheduleSuccess;
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.brandTealDeep,
          ),
        );
      } else {
        setState(() {
          _error = LearningSupportError.scheduleFailed;
          _saving = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = LearningSupportError.scheduleFailed;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);

  Widget _buildHeader(JisrColors c) {
    return Row(
      children: [
        const Icon(AppIcons.specialist, color: AppColors.brandBlueLight, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.supportSessionRequestTitle(widget.request.childName),
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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(LearningSupportPresentation.urgency(widget.request.urgency, context.l10n),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                LearningSupportPresentation.reason(widget.request.reason, context.l10n),
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
        color: AppColors.brandGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.event, color: AppColors.brandGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.supportScheduledDate(LearningSupportPresentation.date(s, context.l10n)),
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
                ? context.l10n.supportChooseDate
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
            label: _time == null ? context.l10n.supportChooseTime : _time!.format(context),
            onTap: _pickTime,
            color: AppColors.brandTealDeep,
            c: c,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingLinkField() {
    return TextField(
      controller: _meetingLinkCtrl,
      decoration: InputDecoration(
        labelText: context.l10n.supportMeetingLinkField,
        prefixIcon: Icon(Icons.link),
        hintText: 'https://meet.google.com/...',
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.supportParentNotes,
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
            child: Text(context.l10n.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandTealDeep,
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
              _saving ? '...' : isScheduled ? context.l10n.edit : context.l10n.supportConfirm,
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
