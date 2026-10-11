// lib/services/simple_language_service.dart
// خدمة تبسيط اللغة — تحوّل النصوص المعقدة إلى كلمات بسيطة

class SimpleLanguageService {
  SimpleLanguageService._();
  static final SimpleLanguageService instance = SimpleLanguageService._();

  /// قاموس التبسيط
  static const Map<String, String> _dictionary = {
    // جمل طويلة
    'الرجاء الانتظار': 'انتظر',
    'تم بنجاح': 'تمام!',
    'حدث خطأ': 'في مشكلة',
    'لا يمكن': 'ما نقدر',
  };

  /// تبسيط نص واحد
  String simplify(String text) {
    var result = text;
    _dictionary.forEach((complex, simple) {
      result = result.replaceAll(complex, simple);
    });
    return result;
  }

  /// Divide reading into manageable visual lines without deleting words.
  String readingLines(String text, {int wordsPerLine = 8}) {
    final limit = wordsPerLine < 1 ? 1 : wordsPerLine;
    return text.split('\n').map((paragraph) {
      final words = paragraph.trim().split(RegExp(r'\s+'));
      if (paragraph.trim().isEmpty) return '';
      final lines = <String>[];
      final line = <String>[];
      for (final word in words) {
        line.add(word);
        // Prefer sentence boundaries; retain every word and punctuation mark.
        if (line.length >= limit || RegExp(r'[.!?؟؛]$').hasMatch(word)) {
          lines.add(line.join(' '));
          line.clear();
        }
      }
      if (line.isNotEmpty) lines.add(line.join(' '));
      return lines.join('\n');
    }).join('\n');
  }

  /// تقصير الجمل (حد أقصى 5 كلمات)
  String shorten(String text, {int maxWords = 5}) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')}...';
  }

  /// تبسيط + تقصير
  String process(String text) {
    return readingLines(simplify(text));
  }
}