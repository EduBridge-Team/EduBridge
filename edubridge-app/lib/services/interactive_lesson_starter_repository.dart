import 'dart:convert';

import 'package:flutter/services.dart';
import '../models/interactive_lesson.dart';

/// Read-only offline starter library. These are templates, not published lessons.
class InteractiveLessonStarterRepository {
  const InteractiveLessonStarterRepository();

  static const assetPath =
      'assets/interactive_lessons/starter_lessons_ar_ps.json';

  Future<InteractiveLessonCatalog> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid lesson catalog');
    }
    return InteractiveLessonCatalog.fromJson(data);
  }
}
