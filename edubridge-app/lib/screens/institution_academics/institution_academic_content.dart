import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_academic_records.dart';
import '../academics/academic_filter_button.dart';

/// Presentation only: names come from validated relationships, never join labels.
class InstitutionAcademicContent extends StatefulWidget {
  const InstitutionAcademicContent({super.key, required this.records});
  final InstitutionAcademicRecords records;
  @override
  State<InstitutionAcademicContent> createState() => _InstitutionAcademicContentState();
}

class _InstitutionAcademicContentState extends State<InstitutionAcademicContent> {
  int? _yearId, _gradeId;

  @override
  void didUpdateWidget(covariant InstitutionAcademicContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final records = widget.records;
    if (oldWidget.records.organizationId != records.organizationId ||
        oldWidget.records.organizationSlug != records.organizationSlug ||
        oldWidget.records.school.id != records.school.id) {
      _yearId = null;
      _gradeId = null;
    }
    if (!records.years.any((year) => year.id == _yearId)) _yearId = null;
    if (!records.grades.any((grade) => grade.id == _gradeId)) _gradeId = null;
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AcademicFilterButton(
              key: const ValueKey('institution-section-year-filter'),
              label: l.academicYears,
              options: years,
              value: _yearId,
              onChanged: (value) => setState(() => _yearId = value),
            ),
            AcademicFilterButton(
              key: const ValueKey('institution-section-grade-filter'),
              label: l.academicGrades,
              options: grades,
              value: _gradeId,
              onChanged: (value) => setState(() => _gradeId = value),
            ),
          ],
        ),
        group('institution-academic-sections', l.academicSections, [
          for (final section in records.sections.where((section) =>
              (_yearId == null || section.yearId == _yearId) &&
              (_gradeId == null || section.gradeId == _gradeId)))
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
