import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// Authenticated institution statistics from the existing scoped report API.
/// No global user listings and no fabricated specialist totals.
class InstitutionStatisticsScreen extends StatefulWidget {
  const InstitutionStatisticsScreen({super.key});

  @override
  State<InstitutionStatisticsScreen> createState() => _InstitutionStatisticsScreenState();
}

class _InstitutionStatisticsScreenState extends State<InstitutionStatisticsScreen> {
  late Future<Map<String, dynamic>?> _future;

  bool get _en => Localizations.localeOf(context).languageCode == 'en';
  String _label(String ar, String en) => _en ? en : ar;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final userId = await ApiService.getUserId();
    if (userId == null) return null;
    final preferences = await SharedPreferences.getInstance();
    final slug = preferences.getString('institution_slug_$userId');
    if (slug == null || slug.isEmpty) return null;
    final response = await ApiService.authGet(
      '/institutions/${Uri.encodeComponent(slug)}/management-report',
    );
    if (response.statusCode != 200) {
      final data = ApiService.decodeMap(response.body);
      throw Exception(data['error'] ?? data['message'] ?? 'Report unavailable');
    }
    return ApiService.decodeMap(response.body);
  }

  Widget _metric(String label, dynamic count, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppColors.brandBlue),
        const SizedBox(height: 6),
        Text(count is num ? '$count' : '—',
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BrandAppBar(
      leading: const BackButton(),
      title: Text(_label('الإحصائيات الشاملة', 'Comprehensive Statistics')),
    ),
    body: FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_label('تعذّر تحميل التقرير. تحقق من صلاحيات المؤسسة.',
                'Unable to load report. Check institution access.')),
          ));
        }
        final data = snapshot.data;
        if (data == null) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_label(
              'حمّل بيانات مؤسستك مرة من شاشة إدارة المدارس أولًا.',
              'Load your institution in School Management once to view statistics.',
            )),
          ));
        }
        final rawSummary = data['summary'];
        final summary = rawSummary is Map ? rawSummary : const {};
        final rawSchools = data['schools'];
        final schools = rawSchools is List ? rawSchools.whereType<Map>().toList() : <Map>[];
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(_label('ملخص المؤسسة', 'Institution overview'),
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.65,
              children: [
                _metric(_label('المدارس', 'Schools'), summary['schools'], Icons.school_outlined),
                _metric(_label('ملفات الطلاب', 'Student files'), summary['student_files'], Icons.groups_outlined),
                _metric(_label('المعلمون النشطون', 'Active teachers'), summary['active_teachers'], Icons.person_outline),
                _metric(_label('الأخصائيون', 'Specialists'), null, Icons.medical_services_outlined),
                _metric(_label('التسجيلات النشطة', 'Active enrollments'), summary['active_enrollments'], Icons.fact_check_outlined),
                _metric(_label('جلسات الحضور', 'Attendance sessions'), summary['attendance_sessions'], Icons.calendar_month_outlined),
              ],
            ),
            const SizedBox(height: 6),
            Text(_label('عدد الأخصائيين غير متاح في API الحالي.',
                'Specialist count is not provided by the current API.')),
            const SizedBox(height: 20),
            Text(_label('تفاصيل المدارس', 'School breakdown'),
              style: Theme.of(context).textTheme.titleLarge),
            if (schools.isEmpty)
              Padding(padding: const EdgeInsets.all(14),
                child: Text(_label('لا توجد مدارس مسجلة.', 'No schools registered.'))),
            for (final school in schools) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${school['school_name'] ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _line(_label('الشعب الدراسية', 'Sections'), school['sections']),
                    _line(_label('التسجيلات النشطة', 'Active enrollments'), school['active_enrollments']),
                    _line(_label('حصص الجدول', 'Timetable entries'), school['timetable_entries']),
                    _line(_label('جلسات الحضور', 'Attendance sessions'), school['attendance_sessions']),
                    const Divider(),
                    Text(_label('الحضور والغياب', 'Attendance status'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (school['attendance'] is Map) ...[
                      _line(_label('حاضر', 'Present'), school['attendance']['present']),
                      _line(_label('غائب', 'Absent'), school['attendance']['absent']),
                      _line(_label('متأخر', 'Late'), school['attendance']['late']),
                      _line(_label('بعذر', 'Excused'), school['attendance']['excused']),
                    ],
                  ]),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget _line(String name, dynamic number) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Text(name)),
      Text(number is num ? '$number' : '—',
        style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );
}
