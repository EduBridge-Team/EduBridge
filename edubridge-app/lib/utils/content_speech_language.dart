/// Voice selection only: never translates or rewrites authored content.
abstract final class ContentSpeechLanguage {
  static String resolve(String text, {String? override, String fallback = 'ar'}) {
    if (override != null && override.trim().isNotEmpty) return override;
    final arabic = RegExp(r'[ء-يٮ-ۓ]').allMatches(text).length;
    final latin = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (arabic == 0 && latin == 0) return fallback;
    return arabic >= latin ? 'ar' : 'en';
  }
}
