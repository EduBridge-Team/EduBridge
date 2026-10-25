import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/academic_catalog.dart';
import 'academic_filter_button.dart';

/// Filters a validated catalog locally without changing enrollment or API scope.
class AcademicSectionsPanel extends StatefulWidget {
  const AcademicSectionsPanel({
    super.key,
    required this.catalog,
    this.enabled = true,
  });

  final AcademicCatalog catalog;
  final bool enabled;

  @override
  State<AcademicSectionsPanel> createState() => _AcademicSectionsPanelState();
}

class _AcademicSectionsPanelState extends State<AcademicSectionsPanel> {
  int? _year, _grade;

  @override
  void didUpdateWidget(covariant AcademicSectionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final data = widget.catalog;
    if (oldWidget.catalog.school.id != data.school.id) {
      _year = _grade = null;
    }
    if (!data.years.any((item) => item.id == _year)) _year = null;
    if (!data.grades.any((item) => item.id == _grade)) _grade = null;
  }

  void _selectYear(int? value) {
    if (!widget.enabled ||
        (value != null &&
            !widget.catalog.years.any((item) => item.id == value))) {
      return;
    }
    setState(() => _year = value);
  }

  void _selectGrade(int? value) {
    if (!widget.enabled ||
        (value != null &&
            !widget.catalog.grades.any((item) => item.id == value))) {
      return;
    }
    setState(() => _grade = value);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.catalog;
    final l10n = context.l10n;
    final years = {for (final year in data.years) year.id: year.name};
    final grades = {for (final grade in data.grades) grade.id: grade.name};
    final sections = data.sections
        .where(
          (section) =>
              (_year == null || section.yearId == _year) &&
              (_grade == null || section.gradeId == _grade),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.sections.isNotEmpty) ...[
          AcademicFilterButton(
            key: const ValueKey('academic-filter-year'),
            label: l10n.academicYears,
            options: years,
            value: _year,
            onChanged: widget.enabled ? _selectYear : null,
          ),
          AcademicFilterButton(
            key: const ValueKey('academic-filter-grade'),
            label: l10n.academicGrades,
            options: grades,
            value: _grade,
            onChanged: widget.enabled ? _selectGrade : null,
          ),
        ],
        if (sections.isEmpty)
          Text(
            l10n.academicEmpty,
            key: const ValueKey('academic-sections-empty'),
          ),
        for (final section in sections)
          Card(
            key: ValueKey('academic-section-${section.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(section.name),
                  Text(years[section.yearId]!),
                  Text(grades[section.gradeId]!),
                  Text('${l10n.academicCapacity}: ${section.capacity}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
