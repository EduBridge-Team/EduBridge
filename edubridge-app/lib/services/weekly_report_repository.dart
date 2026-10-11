import 'dart:convert';
import 'package:http/http.dart' as http;

class WeeklyReportRepository {
  final Future<http.Response> Function(String) get;

  WeeklyReportRepository({required this.get});

  Future<Map<String, dynamic>> _read(String path) async {
    final response = await get(path);
    if (response.statusCode != 200) {
      throw Exception('تعذّر تحميل التقارير');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getReport({
    required int childId,
    DateTime? weekStart,
  }) async {
    // Let the API choose its current week, exactly as it does when saving.
    var path = '/reports/weekly?child_id=$childId';
    if (weekStart != null) {
      final date = '${weekStart.year.toString().padLeft(4, '0')}-'
          '${weekStart.month.toString().padLeft(2, '0')}-'
          '${weekStart.day.toString().padLeft(2, '0')}';
      path += '&week_start=$date';
    }
    final data = await _read(path);
    if (!data.containsKey('report')) throw const FormatException('Missing report');
    return data['report'] == null
        ? null
        : Map<String, dynamic>.from(data['report'] as Map);
  }

  Future<List<dynamic>> getHistory(int childId) async {
    final data = await _read('/reports/weekly/child/$childId');
    return List<dynamic>.from(data['reports'] as List);
  }
}
