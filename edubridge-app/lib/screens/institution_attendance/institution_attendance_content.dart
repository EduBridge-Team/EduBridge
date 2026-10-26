import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../model/institutions/institution_attendance.dart';

String attendanceStatusLabel(AppLocalizations l, InstitutionAttendanceStatus status) => switch (status) {
  InstitutionAttendanceStatus.present => l.institutionAttendancePresent,
  InstitutionAttendanceStatus.absent => l.institutionAttendanceAbsent,
  InstitutionAttendanceStatus.late => l.institutionAttendanceLate,
  InstitutionAttendanceStatus.excused => l.institutionAttendanceExcused,
};

class InstitutionAttendanceContent extends StatelessWidget {
  const InstitutionAttendanceContent({super.key, required this.data, required this.onOpen});
  final InstitutionAttendanceView data;
  final ValueChanged<int>? onOpen;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = data.session;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(data.academic.school.name, style: Theme.of(context).textTheme.titleLarge),
      if (session == null) ...[
        Text(l.institutionAttendanceLimit),
        if (data.sessions.isEmpty) Text(l.institutionAttendanceEmpty),
        for (final item in data.sessions) Card(
          child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _SessionSummary(data: data, session: item),
              OutlinedButton(key: ValueKey('attendance-session-${item.id}'),
                onPressed: onOpen == null ? null : () => onOpen!(item.id),
                child: Text(l.institutionAttendanceDetails)),
            ],
          )),
        ),
      ] else ...[
        _SessionSummary(data: data, session: session),
        if (session.note != null && session.note!.isNotEmpty) Text(session.note!),
        if (data.records.isEmpty) Text(l.institutionAttendanceNoRecords),
        for (final record in data.records) Card(
          key: ValueKey('attendance-child-${record.childId}'),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(record.childName, style: Theme.of(context).textTheme.titleMedium),
              Text(attendanceStatusLabel(l, record.status)),
              if (record.note != null && record.note!.isNotEmpty) Text(record.note!),
            ],
          )),
        ),
      ],
    ]);
  }
}
class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.data, required this.session});
  final InstitutionAttendanceView data;
  final InstitutionAttendanceSession session;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final subject = data.subjectLabel(session);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(data.sectionLabel(session)),
      Text(MaterialLocalizations.of(context).formatMediumDate(session.date)),
      if (session.period != null) Text('${l.institutionAttendancePeriod}: ${session.period}'),
      if (subject != null) Text(subject),
      Text(session.closed ? l.institutionAttendanceClosed : l.institutionAttendanceOpen),
    ]);
  }
}
