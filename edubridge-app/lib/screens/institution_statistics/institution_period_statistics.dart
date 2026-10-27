import 'package:flutter/material.dart';

/// Optional period counters use server values only; current totals are never
/// substituted for missing historical/event counts.
class InstitutionPeriodStatistics extends StatelessWidget {
  const InstitutionPeriodStatistics({super.key, required this.values});
  final Map<String, int?> values;
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final labels = {
      'schools_created': en ? 'Schools created in period' : 'مدارس أُنشئت خلال الفترة',
      'teachers_joined': en ? 'Teachers joined in period' : 'معلمون انضموا خلال الفترة',
      'student_files_created': en ? 'Student files created in period' : 'ملفات طلاب أُنشئت خلال الفترة',
      'enrollments_started': en ? 'Enrollments started in period' : 'تسجيلات بدأت خلال الفترة',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(en ? 'Selected-period statistics' : 'إحصائيات الفترة المختارة',
        style: Theme.of(context).textTheme.titleLarge),
      if (labels.keys.any((key) => values[key] == null)) Text(
        en ? 'Some period data is not available yet.' : 'بعض بيانات الفترة غير متاحة بعد.'),
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth >= 600 * scale ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final label in labels.entries) SizedBox(width: width, child: Card(
            key: ValueKey('statistics-period-${label.key}'), child: Padding(padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(label.value), Text(values[label.key]?.toString() ?? '—',
                  style: Theme.of(context).textTheme.headlineSmall),
                if (values[label.key] == null) Text(en ? 'Period data unavailable' : 'بيانات الفترة غير متاحة'),
              ])))),
        ]);
      }),
      const SizedBox(height: 20),
    ]);
  }
}
