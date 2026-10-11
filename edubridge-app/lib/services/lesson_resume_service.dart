import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Reading position only; this never records completion or awards stars.
class LessonResumeService {
  const LessonResumeService();

  String _key(int owner, int child, int lesson) =>
      'lesson_reading_v1_${owner}_${child}_$lesson';

  Future<int> load(int owner, int child, int lesson, String version, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(owner, child, lesson));
    if (raw == null || count <= 0) return 0;
    try {
      final value = jsonDecode(raw);
      if (value is! Map || value['version'] != version) return 0;
      final step = value['step'];
      return step is int && step >= 0 && step < count ? step : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> save(int owner, int child, int lesson, String version, int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(owner, child, lesson),
        jsonEncode({'version': version, 'step': step}));
  }
}
