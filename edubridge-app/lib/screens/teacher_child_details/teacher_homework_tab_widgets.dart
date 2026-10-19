part of 'teacher_child_details_screen.dart';

extension _HomeworkTabWidgets on _HomeworkTabState {
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _filterChip(context.l10n.all, 'all', _homeworks.length, AppColors.brandBlue),
          _filterChip(context.l10n.homeworkPendingFilter, 'pending', _pendingCount, AppColors.orange),
          _filterChip(context.l10n.toGrade, 'submitted', _submittedCount, AppColors.brandTeal),
          _filterChip(context.l10n.graded, 'graded', _gradedCount, AppColors.green),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count, Color color) {
    final selected = _filter == value;
    return ChoiceChip(
      selected: selected,
      label: Text('$label ($count)'),
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: selected ? color : JisrColors.of(context).muted),
      onSelected: (_) => _updateHomeworkState(() => _filter = value),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(context.sharedMessage(_error),
                style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: Text(context.l10n.retryAction),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 92),
        children: [
          const SizedBox(height: 80),
          Icon(AppIcons.homework,
              size: 80, color: JisrColors.of(context).muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _homeworks.isEmpty
                  ? context.l10n.homeworkChildEmpty
                  : context.l10n.homeworkFilterEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
      itemCount: list.length,
      itemBuilder: (context, i) => _buildHomeworkCard(list[i]),
    );
  }

  Widget _buildHomeworkCard(Homework hw) {
    final c = JisrColors.of(context);
    final submission = _submissionFor(hw);
    final isPending = submission == null;
    final isGraded = submission?.grade != null;
    final isOverdue = hw.isOverdue && isPending;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isPending) {
      if (isOverdue) {
        statusColor = AppColors.red;
        statusLabel = context.l10n.homeworkOverduePending;
        statusIcon = AppIcons.warning;
      } else {
        statusColor = AppColors.orange;
        statusLabel = context.l10n.homeworkNotSubmittedYet;
        statusIcon = AppIcons.clock;
      }
    } else if (isGraded) {
      statusColor = AppColors.green;
      statusLabel = context.l10n.graded;
      statusIcon = AppIcons.check;
    } else {
      statusColor = AppColors.brandTeal;
      statusLabel = context.l10n.homeworkAwaitingGrade;
      statusIcon = AppIcons.clock;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(hw, statusColor, statusLabel, statusIcon, c),
            if (hw.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(hw.description,
                  style: TextStyle(fontSize: 14, color: c.body, height: 1.4)),
            ],
            const SizedBox(height: 10),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 10),
            _buildMetaRow(hw, isOverdue, c),
            if (submission != null) ...[
              const SizedBox(height: 12),
              _buildSubmissionBox(submission, isGraded, c),
            ],
            const SizedBox(height: 12),
            _buildActionButton(
                hw, submission, isPending, isGraded, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Homework hw, Color statusColor, String statusLabel,
      IconData statusIcon, JisrColors c) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hw.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: c.heading,
            ),
          ),
        ),
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Flexible(child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              )),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMetaRow(Homework hw, bool isOverdue, JisrColors c) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(AppIcons.calendar, size: 15, color: isOverdue ? AppColors.red : c.muted),
          const SizedBox(width: 4),
          Flexible(child: Text(context.l10n.homeworkDueDate(MaterialLocalizations.of(context).formatMediumDate(hw.dueDate)),
          style: TextStyle(fontSize: 12, color: isOverdue ? AppColors.red : c.muted,
            fontWeight: isOverdue ? FontWeight.bold : null))),
        ]),
        if (hw.subject != null && hw.subject!.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(AppIcons.lesson, size: 15, color: AppColors.brandBlue),
            const SizedBox(width: 4),
            Flexible(child: Text(hw.subject!, style: const TextStyle(fontSize: 12, color: AppColors.brandBlue))),
          ]),
      ],
    );
  }

  Widget _buildSubmissionBox(
      HomeworkSubmission submission, bool isGraded, JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGraded
            ? AppColors.green.withValues(alpha: 0.08)
            : AppColors.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGraded
              ? AppColors.green.withValues(alpha: 0.3)
              : AppColors.brandTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                submission.isLate ? AppIcons.clock : AppIcons.check,
                size: 16,
                color: submission.isLate ? AppColors.orange : AppColors.green,
              ),
              const SizedBox(width: 6),
              Text(
                submission.isLate ? context.l10n.homeworkSubmittedLate : context.l10n.homeworkSubmittedOnTime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: submission.isLate ? AppColors.orange : AppColors.green,
                ),
              ),
              Text(
                '${MaterialLocalizations.of(context).formatShortDate(submission.submittedAt)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(submission.submittedAt))}',
                style: TextStyle(fontSize: 11, color: c.muted),
              ),
            ],
          ),
          if (submission.textAnswer != null &&
              submission.textAnswer!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(context.l10n.homeworkStudentAnswer,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c.muted,
                )),
            const SizedBox(height: 2),
            Text(submission.textAnswer!,
                style: TextStyle(fontSize: 13, color: c.body, height: 1.4)),
          ],
          if (submission.grade != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(AppIcons.starFilled,
                    color: AppColors.yellow, size: 18),
                const SizedBox(width: 4),
                Expanded(child: Text(
                  context.l10n.homeworkGradeValue(submission.grade.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDeep,
                  ),
                )),
              ],
            ),
          ],
          if (submission.feedback != null &&
              submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.homeworkFeedbackValue(submission.feedback!),
              style: TextStyle(
                fontSize: 12,
                color: c.body,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    Homework hw,
    HomeworkSubmission? submission,
    bool isPending,
    bool isGraded,
    Color statusColor,
  ) {
    if (isPending) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.orange,
            side: BorderSide(
              color: AppColors.orange.withValues(alpha: 0.5),
              width: 1.5,
            ),
            minimumSize: const Size(0, 44),
          ),
          icon: const Icon(AppIcons.notifications, size: 18),
          label: Text(context.l10n.homeworkStudentNotSubmitted),
          onPressed: null,
        ),
      );
    }
    if (!isGraded) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 46),
          ),
          icon: const Icon(AppIcons.grade, size: 20),
          label: Text(
            context.l10n.homeworkGradeAction,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _openGradeSheet(hw, submission!),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          minimumSize: const Size(0, 44),
        ),
        icon: const Icon(AppIcons.edit, size: 18),
        label: Text(context.l10n.homeworkEditGrade),
        onPressed: () => _openGradeSheet(hw, submission!),
      ),
    );
  }
}
