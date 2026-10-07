import 'package:http/http.dart' as http;
import '../../../services/lesson_captions.dart';

/// Optional captions must never prevent the primary video from playing.
class LessonCaptionRepository {
  LessonCaptionRepository({Future<http.Response> Function(Uri)? get})
      : _get = get ?? ((uri) => http.get(uri));

  final Future<http.Response> Function(Uri) _get;

  Future<List<LessonCaption>> load(String url) async {
    try {
      final response = await _get(Uri.parse(url));
      if (response.statusCode == 200) return parseLessonCaptions(response.body);
    } catch (_) {
      // Preserve the existing optional-caption fallback.
    }
    return [];
  }
}
