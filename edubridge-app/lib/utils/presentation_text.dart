import 'package:flutter/material.dart' show StringCharacters;

/// Shared text conventions; callers keep their own whitespace/fallback policy.
class PresentationText {
  static String initial(Object? value, {String fallback = '؟', bool trim = false,
      bool uppercase = false}) {
    var text = value?.toString() ?? '';
    if (trim) text = text.trim();
    final result = text.isEmpty ? fallback : text.characters.first;
    return uppercase ? result.toUpperCase() : result;
  }

  static String clock(DateTime date, {bool padHour = false}) {
    final hour = padHour ? date.hour.toString().padLeft(2, '0') : '${date.hour}';
    return '$hour:${date.minute.toString().padLeft(2, '0')}';
  }
}
