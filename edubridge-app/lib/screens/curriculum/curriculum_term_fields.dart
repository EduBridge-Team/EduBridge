import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/academic_catalog.dart';
import '../academics/academic_choice_field.dart';

class CurriculumTermFields extends StatelessWidget {
  const CurriculumTermFields({
    super.key,
    required this.years,
    required this.yearId,
    required this.position,
    required this.start,
    required this.end,
    required this.onYear,
    required this.onDate,
  });
  final List<AcademicYear> years;
  final int? yearId;
  final TextEditingController position;
  final DateTime? start, end;
  final ValueChanged<int>? onYear;
  final ValueChanged<bool>? onDate;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcademicChoiceField(
          key: const ValueKey('curriculum-year'),
          label: l10n.academicYears,
          options: {for (final year in years) year.id: year.name},
          value: yearId,
          requiredMessage: l10n.academicRequired,
          onChanged: onYear,
        ),
        TextFormField(
          key: const ValueKey('curriculum-position'),
          controller: position,
          enabled: onYear != null,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.curriculumPosition),
        ),
        OutlinedButton(
          key: const ValueKey('curriculum-start'),
          onPressed: onDate == null || yearId == null
              ? null
              : () => onDate!(true),
          child: Text(
            '${l10n.academicStart}: ${start == null ? '—' : dates.formatMediumDate(start!)}',
          ),
        ),
        OutlinedButton(
          key: const ValueKey('curriculum-end'),
          onPressed: onDate == null || yearId == null
              ? null
              : () => onDate!(false),
          child: Text(
            '${l10n.academicEnd}: ${end == null ? '—' : dates.formatMediumDate(end!)}',
          ),
        ),
      ],
    );
  }
}
