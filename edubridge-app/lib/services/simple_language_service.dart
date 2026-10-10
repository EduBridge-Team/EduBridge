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
      for (var start = 0; start < words.length; start += limit) {
        final end = (start + limit).clamp(0, words.length);
        lines.add(words.sublist(start, end).join(' '));
      }
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