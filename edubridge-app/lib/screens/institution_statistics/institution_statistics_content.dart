import 'package:flutter/material.dart';
import '../../model/institutions/institution_statistics.dart';
import '../../theme.dart';

class InstitutionStatisticsContent extends StatelessWidget {
  const InstitutionStatisticsContent({super.key, required this.data, this.hasPeriod = false});
  final InstitutionStatistics data;
  final bool hasPeriod;
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
            LayoutBuilder(builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(spacing: 8, runSpacing: 8, children: [
                SizedBox(width: width, child: _metric(label('المدارس', 'Schools'), data.summary['schools'], Icons.school_outlined)),
                SizedBox(width: width, child: _metric(label('المعلمون', 'Teachers'), data.summary['teachers'], Icons.person_outline)),
                SizedBox(width: width, child: _metric(label('الأخصائيون', 'Specialists'), data.summary['specialists'], Icons.medical_services_outlined)),
                SizedBox(width: width, child: _metric(label('الطلاب', 'Students'), data.summary['student_files'], Icons.groups_outlined)),
              ]);
            }),
            Text(label(hasPeriod ? 'الحضور خلال الفترة المختارة' : 'الحضور لكل التواريخ',
              hasPeriod ? 'Attendance in selected period' : 'Attendance across all dates'),
              style: Theme.of(context).textTheme.titleLarge),
            _metric(label('جلسات الحضور', 'Attendance sessions'), data.summary['attendance_sessions'], Icons.calendar_month_outlined),

            ...[
              for (final status in ['present', 'absent', 'late', 'excused'])
                _line(label({'present': 'حاضر', 'absent': 'غائب', 'late': 'متأخر', 'excused': 'بعذر'}[status]!,
                  {'present': 'Present', 'absent': 'Absent', 'late': 'Late', 'excused': 'Excused'}[status]!), data.attendanceTotal(status)),
              _line(label('نسبة الحضور', 'Present rate'), data.presentRate == null ? null : '${data.presentRate!.toStringAsFixed(1)}%'),
            ],
            Text(label('الحضور حسب المدرسة', 'Attendance by school'),
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
      Text(number?.toString() ?? '—',
        style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );
}
