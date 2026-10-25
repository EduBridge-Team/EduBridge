import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';
import '../domain/student_learning_metrics.dart';

class StudentLearningMetricsRepository {
  StudentLearningMetricsRepository({
    Future<http.Response> Function(String)? get,
  }) : _get = get ?? ApiService.authGet;

  final Future<http.Response> Function(String) _get;

  Future<StudentLearningMetrics> load(int childId) async {
    final responses = await Future.wait([
      _get('/children/$childId/lessons'),
      _get('/progress/child/$childId'),
    ]);
    return StudentLearningMetrics.fromData(
      lessons: responses[0].statusCode == 200
          ? ApiService.decodeMap(responses[0].body)['lessons']
          : null,
      progress: responses[1].statusCode == 200
          ? ApiService.decodeMap(responses[1].body)['progress']
          : null,
    );
  }
}
