import '../services/api_service.dart';

class InteractiveDraftRepository {
  const InteractiveDraftRepository();

  Future<int> save({
    required String templateId,
    required String title,
    required String objective,
  }) async {
    final response = await ApiService.authPost('/interactive-lesson-drafts', {
      'template_id': templateId,
      'title': title.trim(),
      'objective': objective.trim(),
    });
    if (response.statusCode != 201) {
      throw StateError('Unable to save lesson draft (HTTP ${response.statusCode})');
    }
    final data = ApiService.decodeMap(response.body);
    final draft = data['draft'];
    if (draft is! Map || draft['id'] is! int || (draft['id'] as int) <= 0) {
      throw const FormatException('Invalid saved draft receipt');
    }
    return draft['id'] as int;
  }
}
