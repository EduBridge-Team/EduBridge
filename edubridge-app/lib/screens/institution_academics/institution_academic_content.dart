import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_academic_records.dart';

/// Presentation only: names come from validated relationships, never join labels.
class InstitutionAcademicContent extends StatelessWidget {
  const InstitutionAcademicContent({super.key, required this.records});
  final InstitutionAcademicRecords records;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = MaterialLocalizations.of(context);
    final years = {for (final y in records.curriculum.years) y.id: y.name};
    final grades = {for (final g in records.grades) g.id: g.name};
    Widget item(String title, List<String> lines) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            for (final line in lines) Text(line),
          ],
        ),
      ),
    );
    Widget group(String key, String title, List<Widget> children) =>
        ExpansionTile(
          key: ValueKey(key),
          title: Text('$title (${children.length})'),
          children: children.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.academicEmpty),
                  ),
                ]
              : children,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          records.school.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        group('institution-academic-years', l.academicYears, [
          for (final year in records.curriculum.years)
            item(year.name, [
              '${l.academicStart}: ${dates.formatMediumDate(year.start)}',
              '${l.academicEnd}: ${dates.formatMediumDate(year.end)}',
              if (year.current) l.academicCurrent,
            ]),
        ]),
        group('institution-academic-grades', l.academicGrades, [
          for (final grade in records.grades) item(grade.name, []),
        ]),
        group('institution-academic-sections', l.academicSections, [
          for (final section in records.sections)
            item(section.name, [
              '${l.academicYears}: ${years[section.yearId]}',
              '${l.academicGrades}: ${grades[section.gradeId]}',
              if (section.capacity != null)
                '${l.academicCapacity}: ${section.capacity}',
              if (section.teacher?.trim().isNotEmpty == true)
                '${l.institutionAcademicTeacher}: ${section.teacher}',
            ]),
        ]),
        group('institution-academic-terms', l.curriculumTerms, [
          for (final term in records.curriculum.terms)
            item(term.name, [
              '${l.academicYears}: ${years[term.yearId]}',
              '${l.curriculumPosition}: ${term.position}',
              '${l.academicStart}: ${dates.formatMediumDate(term.start)}',
              '${l.academicEnd}: ${dates.formatMediumDate(term.end)}',
            ]),
        ]),
        group('institution-academic-subjects', l.curriculumSubjects, [
          for (final subject in records.curriculum.subjects)
            item(subject.name, [
              if (subject.code != null) subject.code!,
              subject.active ? l.curriculumActive : l.curriculumInactive,
            ]),
        ]),
      ],
    );
  }
}
