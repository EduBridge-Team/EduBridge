// Learning-support session card.
part of 'learning_support_meetings_screen.dart';

class _SessionCard extends StatelessWidget {
  final LearningSupportMeeting session;

  const _SessionCard({required this.session});

  String get _typeLabel {
    switch (session.type) {
      case LearningSupportMeetingType.learningPlanning:
        return 'اجتماع تخطيط تعليمي';
      case LearningSupportMeetingType.followUp:
        return 'متابعة';
      case LearningSupportMeetingType.teamReview:
        return 'مراجعة فريق الدعم';
      case LearningSupportMeetingType.parentReview:
        return 'متابعة مع ولي الأمر';
      case LearningSupportMeetingType.groupSupport:
        return 'دعم تعليمي جماعي';
    }
  }

  IconData get _typeIcon {
    switch (session.type) {
      case LearningSupportMeetingType.learningPlanning:
        return AppIcons.plan;
      case LearningSupportMeetingType.followUp:
        return AppIcons.refresh;
      case LearningSupportMeetingType.teamReview:
        return AppIcons.warning;
      case LearningSupportMeetingType.parentReview:
        return AppIcons.parent;
      case LearningSupportMeetingType.groupSupport:
        return AppIcons.users;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case LearningSupportMeetingStatus.scheduled:
        return 'مجدولة';
      case LearningSupportMeetingStatus.completed:
        return 'مكتملة';
      case LearningSupportMeetingStatus.cancelled:
        return 'ملغية';
      case LearningSupportMeetingStatus.noShow:
        return 'لم يحضر';
    }
  }

  Color get _statusColor {
    switch (session.status) {
      case LearningSupportMeetingStatus.scheduled:
        return AppColors.orange;
      case LearningSupportMeetingStatus.completed:
        return AppColors.green;
      case LearningSupportMeetingStatus.cancelled:
      case LearningSupportMeetingStatus.noShow:
        return AppColors.red;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} — $hour:$minute';
  }

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_typeIcon, color: _statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      if (session.childName.isNotEmpty)
                        Text(
                          'الطفل: ${session.childName}',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 12),

            _infoRow(AppIcons.calendar, 'الموعد',
                _formatDate(session.scheduledAt), c),
            const SizedBox(height: 6),
            _infoRow(AppIcons.clock, 'المدة',
                '${session.durationMinutes} دقيقة', c),

            if (session.specialistName.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(AppIcons.specialist, 'المختص',
                  session.specialistName, c),
            ],

            if (session.completedAt != null) ...[
              const SizedBox(height: 6),
              _infoRow(AppIcons.check, 'اكتملت',
                  _formatDate(session.completedAt!), c),
            ],

            if (session.goals != null && session.goals!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('الأهداف', session.goals!, c),
            ],

            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _section('ملاحظات', session.notes!, c),
            ],

            if (session.recommendations != null &&
                session.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _section('التوصيات', session.recommendations!, c),
            ],

            if (session.moodRating != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.sentiment_satisfied,
                      size: 18, color: c.muted),
                  const SizedBox(width: 6),
                  Text(
                    'المشاركة التعليمية: ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: c.muted,
                    ),
                  ),
                  ...List.generate(5, (i) {
                    return Icon(
                      i < session.moodRating!
                          ? AppIcons.starFilled
                          : AppIcons.star,
                      size: 18,
                      color: AppColors.yellow,
                    );
                  }),
                ],
              ),
            ],

            if (session.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: session.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.tintTeal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$t',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.onTint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, JisrColors c) {
    return Row(
      children: [
        Icon(icon, size: 16, color: c.muted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: c.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: c.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, String content, JisrColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tintTeal.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: c.onTint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: c.onTint,
            ),
          ),
        ],
      ),
    );
  }
}
