part of 'learning_support_requests_screen.dart';

extension _ScheduleLearningSupportSheetStateView on _ScheduleLearningSupportSheetState {
  Widget buildView(BuildContext context) {
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
}
