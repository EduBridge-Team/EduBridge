import 'api_service.dart';

class SavedInteractiveDraft {
  const SavedInteractiveDraft({required this.id, required this.version});
  final int id;
  final int version;

  factory SavedInteractiveDraft.fromReceipt(String body) {
    final data = ApiService.decodeMap(body);
    final draft = data['draft'];
    if (draft is! Map || draft['id'] is! int || draft['version'] is! int ||
        (draft['id'] as int) <= 0 || (draft['version'] as int) <= 0) {
      throw const FormatException('Invalid saved draft receipt');
    }
    return SavedInteractiveDraft(
      id: draft['id'] as int, version: draft['version'] as int,
    );
  }
}

class InteractiveDraftRepository {
  const InteractiveDraftRepository();

  Future<SavedInteractiveDraft> save({
    required String templateId,
    required String title,
    required String objective,
    SavedInteractiveDraft? existing,
  }) async {
    final response = existing == null
        ? await ApiService.authPost('/interactive-lesson-drafts', {
            'template_id': templateId,
            'title': title.trim(),
            'objective': objective.trim(),
          })
        : await ApiService.authPut('/interactive-lesson-drafts/${existing.id}', {
            'expected_version': existing.version,
            'title': title.trim(),
            'objective': objective.trim(),
          });
    final expectedCode = existing == null ? 201 : 200;
    if (response.statusCode != expectedCode) {
      throw StateError('Unable to save lesson draft (HTTP ${response.statusCode})');
    }
    final receipt = SavedInteractiveDraft.fromReceipt(response.body);
    if (existing != null &&
        (receipt.id != existing.id || receipt.version != existing.version + 1)) {
      throw const FormatException('Mismatched updated draft receipt');
    }
    if (existing == null && receipt.version != 1) {
      throw const FormatException('Unexpected initial draft version');
    }
    return receipt;
  }
}
