// Learning-support session card.
part of 'learning_support_meetings_screen.dart';

class _SessionCard extends StatelessWidget {
  final LearningSupportMeeting session;

  const _SessionCard({required this.session});

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
                        LearningSupportPresentation.meetingType(session.type, context.l10n),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      if (session.childName.isNotEmpty)
                        Text(
                          context.l10n.supportChildLabel(session.childName),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                    ],
                  ),
                ),
                Flexible(child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    LearningSupportPresentation.meetingStatus(session.status, context.l10n),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                )),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 12),

            _infoRow(AppIcons.calendar, context.l10n.supportAppointment,
                LearningSupportPresentation.date(session.scheduledAt, context.l10n), c),
            const SizedBox(height: 6),
            _infoRow(AppIcons.clock, context.l10n.supportDuration,
                context.l10n.supportDurationMinutes(session.durationMinutes), c),

            if (session.specialistName.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(AppIcons.specialist, context.l10n.specialistLabel,
                  session.specialistName, c),
            ],

            if (session.completedAt != null) ...[
              const SizedBox(height: 6),
              _infoRow(AppIcons.check, context.l10n.supportCompletedAt,
                  LearningSupportPresentation.date(session.completedAt!, context.l10n), c),
            ],

            if (session.goals != null && session.goals!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section(context.l10n.supportGoals, session.goals!, c),
            ],

            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _section(context.l10n.notes, session.notes!, c),
            ],

            if (session.recommendations != null &&
                session.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _section(context.l10n.recommendations, session.recommendations!, c),
            ],

            if (session.moodRating != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.sentiment_satisfied,
                      size: 18, color: c.muted),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.supportParticipation,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: c.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label: ', style: TextStyle(color: c.muted)),
            TextSpan(text: value, style: TextStyle(color: c.body)),
          ]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
