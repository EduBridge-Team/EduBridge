import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Institution counts from the scoped management report.
/// Specialist count is intentionally unavailable in that API response.
class InstitutionSummaryCard extends StatefulWidget {
  const InstitutionSummaryCard({super.key});

  @override
  State<InstitutionSummaryCard> createState() => _InstitutionSummaryCardState();
}

class _InstitutionSummaryCardState extends State<InstitutionSummaryCard> {
  late Future<Map<String, dynamic>?> _summary;

  @override
  void initState() {
    super.initState();
    _summary = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final userId = await ApiService.getUserId();
    if (userId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final slug = prefs.getString('institution_slug_$userId');
    if (slug == null || slug.isEmpty) return null;
    final response = await ApiService.authGet(
      '/institutions/${Uri.encodeComponent(slug)}/management-report',
    );
    if (response.statusCode != 200) {
      throw Exception('تعذّر تحميل إحصائيات المؤسسة');
    }
    final data = ApiService.decodeMap(response.body)['summary'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return FutureBuilder<Map<String, dynamic>?>(
      future: _summary,
      builder: (context, snapshot) {
        final values = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: Text(english ? 'Institution statistics' : 'إحصائيات المؤسسة',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                  IconButton(
                    tooltip: english ? 'Refresh statistics' : 'تحديث الإحصائيات',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() => _summary = _load()),
                  ),
                ]),
                if (snapshot.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snapshot.hasError)
                  Text(english ? 'Could not load statistics. Check institution access.' : 'تعذّر تحميل الإحصائيات. تحقق من صلاحية المؤسسة.')
                else if (values == null)
                  Text(english ? 'Open School Management and load your institution data first.' : 'افتح إدارة المدارس وحمّل بيانات المؤسسة أولًا لعرض الإحصائيات.')
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.1,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _count(english ? 'Schools' : 'المدارس', values['schools']),
                      _count(english ? 'Students' : 'الطلاب', values['student_files']),
                      _count(english ? 'Teachers' : 'المعلمون', values['active_teachers']),
                      _count(english ? 'Specialists' : 'الأخصائيون', null),
                    ],
                  ),
                if (values != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(english ? 'Specialist count is not provided by the institution API yet.' : 'عدد الأخصائيين غير متاح حاليًا في تقرير المؤسسة.',
                      style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _count(String label, dynamic value) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value is num ? '$value' : '—',
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}
