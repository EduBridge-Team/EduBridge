import 'package:flutter/material.dart';
import '../../model/institutions/institution_statistics.dart';
import '../../theme.dart';
import 'institution_period_statistics.dart';

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
            InstitutionPeriodStatistics(values: hasPeriod ? data.periodSummary : const {}),
            Text(label(hasPeriod ? 'الحضور خلال الفترة المختارة' : 'الحضور لكل التواريخ',
              hasPeriod ? 'Attendance in selected period' : 'Attendance across all dates'),
              style: Theme.of(context).textTheme.titleLarge),
            _metric(label('جلسات الحضور', 'Attendance sessions'), data.summary['attendance_sessions'], Icons.calendar_month_outlined),

            ...[
              for (final status in ['present', 'absent', 'late', 'excused'])
                _line(label({'present': 'حاضر', 'absent': 'غائب', 'late': 'متأخر', 'excused': 'بعذر'}[status]!,
                  {'present': 'Present', 'absent': 'Absent', 'late': 'Late', 'excused': 'Excused'}[status]!), _attendanceTotal(status)),
              _line(label('نسبة الحضور', 'Present rate'), _presentRate()),
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
  int? _attendanceTotal(String status) {
    if (data.schools.any((school) => school.attendance[status] == null)) return null;
    return data.schools.fold<int>(0, (sum, school) => sum + school.attendance[status]!);
  }
  String? _presentRate() {
    final counts = [for (final status in ['present', 'absent', 'late', 'excused']) _attendanceTotal(status)];
    if (counts.any((count) => count == null)) return null;
    final total = counts.fold<int>(0, (sum, count) => sum + count!);
    return total == 0 ? null : '${(counts.first! * 100 / total).toStringAsFixed(1)}%';
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
