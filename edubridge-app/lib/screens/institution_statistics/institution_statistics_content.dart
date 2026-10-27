import 'package:flutter/material.dart';
import '../../model/institutions/institution_statistics.dart';
import '../../theme.dart';

class InstitutionStatisticsContent extends StatelessWidget {
  const InstitutionStatisticsContent({super.key, required this.data});
  final InstitutionStatistics data;
  String _label(BuildContext context, String ar, String en) => Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  Widget _metric(String label, int? count, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppColors.brandBlue),
        const SizedBox(height: 6),
        Text(count == null ? '—' : '$count',
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    String label(String ar, String en) => _label(context, ar, en);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label('ملخص المؤسسة', 'Institution overview'),
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final columns = constraints.maxWidth >= 720 * scale ? 3
                  : constraints.maxWidth >= 360 * scale ? 2 : 1;
              final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(spacing: 8, runSpacing: 8, children: [
                for (final metric in <Widget>[
                  _metric(label('المدارس', 'Schools'), data.summary['schools'], Icons.school_outlined),
                  _metric(label('ملفات الطلاب', 'Student files'), data.summary['student_files'], Icons.groups_outlined),
                  _metric(label('المعلمون النشطون', 'Active teachers'), data.summary['active_teachers'], Icons.person_outline),
                  _metric(label('الأخصائيون', 'Specialists'), null, Icons.medical_services_outlined),
                  _metric(label('التسجيلات النشطة', 'Active enrollments'), data.summary['active_enrollments'], Icons.fact_check_outlined),
                  _metric(label('جلسات الحضور', 'Attendance sessions'), data.summary['attendance_sessions'], Icons.calendar_month_outlined),
                ])
                  SizedBox(width: width, child: metric),
              ]);
            }),
            const SizedBox(height: 6),
            Text(label('عدد الأخصائيين غير متاح في API الحالي.',
                'Specialist count is not provided by the current API.')),
            const SizedBox(height: 20),
            Text(label('تفاصيل المدارس', 'School breakdown'),
              style: Theme.of(context).textTheme.titleLarge),
            if (data.schools.isEmpty)
              Padding(padding: const EdgeInsets.all(14),
                child: Text(label('لا توجد مدارس مسجلة.', 'No schools registered.'))),
            for (final school in data.schools) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(school.name,
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _line(label('الشعب الدراسية', 'Sections'), school.counts['sections']),
                    _line(label('التسجيلات النشطة', 'Active enrollments'), school.counts['active_enrollments']),
                    _line(label('حصص الجدول', 'Timetable entries'), school.counts['timetable_entries']),
                    _line(label('جلسات الحضور', 'Attendance sessions'), school.counts['attendance_sessions']),
                    const Divider(),
                    Text(label('الحضور والغياب', 'Attendance status'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                    ...[
                      _line(label('حاضر', 'Present'), school.attendance['present']),
                      _line(label('غائب', 'Absent'), school.attendance['absent']),
                      _line(label('متأخر', 'Late'), school.attendance['late']),
                      _line(label('بعذر', 'Excused'), school.attendance['excused']),
                    ],
                  ]),
                ),
              ),
            ],
          ],
        );
  }
  Widget _line(String name, dynamic number) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Text(name)),
      Text(number is num ? '$number' : '—',
        style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );
}
