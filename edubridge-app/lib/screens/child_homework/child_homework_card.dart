// lib/screens/child_homework/child_homework_card.dart
part of 'child_homework_screen.dart';

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  final int childId;
  final VoidCallback onSubmit;

  const _HomeworkCard({
    required this.homework,
    required this.childId,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large = AccessibilityService.instance
        .profile.value.extraLargeTouchTargets;

    final submission = homework.submissions
        .cast<HomeworkSubmission?>()
        .firstWhere((s) => s?.childId == childId, orElse: () => null);

    final isSubmitted = submission != null;
    final isOverdue = homework.isOverdue && !isSubmitted;

    Color statusColor;
    String statusText;
    if (isSubmitted) {
      statusColor = AppColors.green;
      statusText = submission.isLate ? 'تم التسليم (متأخر)' : 'تم التسليم';
    } else if (isOverdue) {
      statusColor = AppColors.red;
      statusText = 'متأخر';
    } else {
      statusColor = AppColors.orange;
      statusText = 'لم يُسلَّم';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    homework.title,
                    style: TextStyle(
                      fontSize: large ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: large ? 14 : 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (homework.description.isNotEmpty)
              Text(
                homework.description,
                style: TextStyle(
                  fontSize: large ? 17 : 15,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _infoChip(
                  AppIcons.calendar,
                  'التسليم: ${homework.dueDate.day}/${homework.dueDate.month}/${homework.dueDate.year}',
                  isOverdue ? AppColors.red : c.muted,
                ),
                if (homework.subject != null)
                  _infoChip(
                    AppIcons.lesson,
                    homework.subject!,
                    AppColors.brandBlue,
                  ),
                _infoChip(
                  AppIcons.profile,
                  homework.teacherName,
                  c.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isSubmitted)
              _buildSubmittedBox(submission, c, large)
            else
              SizedBox(
                width: double.infinity,
                height: large ? 64 : 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(AppIcons.upload, size: large ? 28 : 24),
                  label: Text(
                    'تسليم الواجب',
                    style: TextStyle(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: onSubmit,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedBox(
      HomeworkSubmission submission, JisrColors c, bool large) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tintGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.check, color: c.success, size: 24),
              const SizedBox(width: 8),
              Text(
                'سلّمت هذا الواجب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: large ? 17 : 15,
                  color: c.onTint,
                ),
              ),
            ],
          ),
          if (submission.textAnswer != null &&
              submission.textAnswer!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'إجابتك: ${submission.textAnswer}',
              style: TextStyle(
                fontSize: large ? 15 : 13,
                color: c.onTint,
              ),
            ),
          ],
          if (submission.grade != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(AppIcons.starFilled,
                    color: AppColors.yellow, size: 22),
                const SizedBox(width: 6),
                Text(
                  'الدرجة: ${submission.grade}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: large ? 17 : 15,
                    color: AppColors.greenDeep,
                  ),
                ),
              ],
            ),
          ],
          if (submission.feedback != null &&
              submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ملاحظة المعلم: ${submission.feedback}',
              style: TextStyle(
                fontSize: large ? 15 : 13,
                color: c.onTint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: color),
        ),
      ],
    );
  }
}