import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../model/institutions/institution_timetable.dart';

Map<int, String> timetableDays(AppLocalizations l) => {0: l.all,
  1: l.timetableSunday, 2: l.timetableMonday, 3: l.timetableTuesday, 4: l.timetableWednesday,
  5: l.timetableThursday, 6: l.timetableFriday, 7: l.timetableSaturday};

class InstitutionTimetableCard extends StatelessWidget {
  const InstitutionTimetableCard({super.key, required this.timetable, required this.entry, this.onChoose});
  final InstitutionTimetable timetable;
  final InstitutionTimetableEntry entry;
  final VoidCallback? onChoose;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(timetable.sectionLabel(entry.sectionId)),
        Text(timetable.academic.curriculum.subjects.firstWhere((s) => s.id == entry.subjectId).name,
          style: Theme.of(context).textTheme.titleMedium),
        Text(entry.teacherName ?? l.timetableNoTeacher),
        Text(timetableDays(l)[entry.weekday]!),
        Text('${l.institutionAttendancePeriod}: ${entry.period}'),
        if (entry.startsAt != null) Text('${l.timetableStarts}: ${entry.startsAt}'),
        if (entry.endsAt != null) Text('${l.timetableEnds}: ${entry.endsAt}'),
        if (entry.room != null && entry.room!.isNotEmpty) Text('${l.timetableRoom}: ${entry.room}'),
        if (onChoose != null) OutlinedButton(key: ValueKey('timetable-substitute-${entry.id}'),
          onPressed: onChoose, child: Text(l.timetableSubstitute)),
      ],
    )));
  }
}
