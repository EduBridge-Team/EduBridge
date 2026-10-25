import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/curriculum_catalog.dart';

class CurriculumRecords extends StatelessWidget {
  const CurriculumRecords({
    super.key,
    required this.catalog,
    required this.onAddTerm,
    required this.onAddSubject,
  });
  final CurriculumCatalog catalog;
  final VoidCallback? onAddTerm, onAddSubject;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          catalog.school.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          l10n.curriculumTerms,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        OutlinedButton.icon(
          key: const ValueKey('curriculum-add-term'),
          onPressed: onAddTerm,
          icon: const Icon(Icons.add),
          label: Text(l10n.curriculumAddTerm),
        ),
        if (catalog.years.isEmpty) Text(l10n.curriculumYearRequired),
        if (catalog.terms.isEmpty) Text(l10n.academicEmpty),
        for (final year in catalog.years)
          for (final term in catalog.terms.where(
            (term) => term.yearId == year.id,
          ))
            Card(
              key: ValueKey('curriculum-term-${term.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(term.name),
                    Text(year.name),
                    Text('${l10n.curriculumPosition}: ${term.position}'),
                    Text(
                      '${dates.formatMediumDate(term.start)} — ${dates.formatMediumDate(term.end)}',
                    ),
                  ],
                ),
              ),
            ),
        Text(
          l10n.curriculumSubjects,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        OutlinedButton.icon(
          key: const ValueKey('curriculum-add-subject'),
          onPressed: onAddSubject,
          icon: const Icon(Icons.add),
          label: Text(l10n.curriculumAddSubject),
        ),
        if (catalog.subjects.isEmpty) Text(l10n.academicEmpty),
        for (final subject in catalog.subjects)
          Card(
            key: ValueKey('curriculum-subject-${subject.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(subject.name),
                  if (subject.code != null) Text(subject.code!),
                  Text(
                    subject.active
                        ? l10n.curriculumActive
                        : l10n.curriculumInactive,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
