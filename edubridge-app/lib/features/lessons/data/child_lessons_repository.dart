import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';
import '../domain/child_lessons_result.dart';

/// Fetches the existing child-scoped lesson and progress endpoints together.
class ChildLessonsRepository {
  ChildLessonsRepository({Future<http.Response> Function(String)? get})
      : _get = get ?? ApiService.authGet;

  final Future<http.Response> Function(String) _get;

  Future<ChildLessonsResult> load(int childId) async {
    try {
      final responses = await Future.wait([
        _get('/children/$childId/lessons'),
        _get('/progress/child/$childId'),
      ]);
      final lessonsResponse = responses[0];
      final progressResponse = responses[1];
      final lessonsData = jsonDecode(lessonsResponse.body);
      if (lessonsResponse.statusCode != 200) {
        return ChildLessonsResult(
          error: lessonsData['error'] ?? 'تعذّر جلب الدروس',
        );
      }

      final doneIds = <int>{};
      if (progressResponse.statusCode == 200) {
        final progress = jsonDecode(progressResponse.body)['progress'] ?? [];
        for (final record in progress) {
          if (record['status'] == 'done' && record['lesson_id'] is int) {
            doneIds.add(record['lesson_id'] as int);
          }
        }
      }
      return ChildLessonsResult(
        lessons: lessonsData['lessons'] ?? [],
        doneLessonIds: doneIds,
      );
    } catch (_) {
      return const ChildLessonsResult(error: 'تعذّر الاتصال بالسيرفر');
    }
  }
}
