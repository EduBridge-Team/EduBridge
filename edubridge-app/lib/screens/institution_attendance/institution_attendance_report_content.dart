import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/institutions/institution_attendance_report.dart';

class InstitutionAttendanceReportContent extends StatelessWidget {
  const InstitutionAttendanceReportContent({super.key, required this.data});
  final InstitutionAttendanceReport data;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = {'present': l.institutionAttendancePresent, 'absent': l.institutionAttendanceAbsent,
      'late': l.institutionAttendanceLate, 'excused': l.institutionAttendanceExcused};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(data.academic.school.name, style: Theme.of(context).textTheme.titleLarge),
      Text(l.attendanceReportDefinition),
      if (data.students.isEmpty) Text(l.attendanceReportEmpty) else ...[
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.attendanceReportSummary, style: Theme.of(context).textTheme.titleMedium),
            for (final status in attendanceReportStatuses) Text('${labels[status]}: ${data.summary[status]}'),
          ]))),
        for (final student in data.students) Card(key: ValueKey('attendance-report-student-${student.id}'),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(student.name, style: Theme.of(context).textTheme.titleMedium),
            Text('${l.attendanceReportSessions}: ${student.total}'),
            for (final status in attendanceReportStatuses) Text('${labels[status]}: ${student.counts[status]}'),
            Text('${l.attendanceReportRate}: ${student.rate == null ? l.attendanceReportNoRate : '${student.rate!.toStringAsFixed(1)}%'}'),
          ]))),
      ],
    ]);
  }
}
