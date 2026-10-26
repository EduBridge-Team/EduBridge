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

class InteractiveDraftSummary {
  const InteractiveDraftSummary({
    required this.id, required this.version, required this.templateId,
    required this.title, required this.objective,
  });
  final int id;
  final int version;
  final String templateId;
  final String title;
  final String objective;

  factory InteractiveDraftSummary.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! int || (raw['id'] as int) <= 0 ||
        raw['version'] is! int || (raw['version'] as int) <= 0 ||
        raw['template_id'] is! String ||
        (raw['template_id'] as String).trim().isEmpty ||
        raw['title'] is! String || (raw['title'] as String).trim().isEmpty ||
        raw['objective'] is! String || (raw['objective'] as String).trim().isEmpty) {
      throw const FormatException('Invalid draft summary');
    }
    return InteractiveDraftSummary(
      id: raw['id'] as int,
      version: raw['version'] as int,
      templateId: raw['template_id'] as String,
      title: raw['title'] as String,
      objective: raw['objective'] as String,
    );
  }
}

class InteractiveDraftRepository {
  Future<List<InteractiveDraftSummary>> list() async {
    final response = await ApiService.authGet('/interactive-lesson-drafts');
    if (response.statusCode != 200) {
      throw StateError('Unable to load lesson drafts (HTTP ${response.statusCode})');
    }
    final data = ApiService.decodeMap(response.body);
    final rows = data['drafts'];
    if (rows is! List) {
      throw const FormatException('Invalid draft list');
    }
    final summaries = rows.map(InteractiveDraftSummary.fromJson).toList();
    if (summaries.map((row) => row.id).toSet().length != summaries.length) {
      throw const FormatException('Duplicate draft ID');
    }
    return List.unmodifiable(summaries);
  }

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
