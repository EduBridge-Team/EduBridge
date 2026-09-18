// lib/services/simple_language_service.dart
// خدمة تبسيط اللغة — تحوّل النصوص المعقدة إلى كلمات بسيطة

class SimpleLanguageService {
  SimpleLanguageService._();
  static final SimpleLanguageService instance = SimpleLanguageService._();

  /// قاموس التبسيط
  static const Map<String, String> _dictionary = {
    // مصطلحات تعليمية
    'المحتوى التعليمي': 'الدرس',
    'التقييم': 'الفحص',
    'الأهداف التعليمية': 'ما نتعلمه',
    'المهارات': 'القدرات',
    'الكفايات': 'المهارات',
    'المنهج': 'الدروس',
    'المراجعة': 'إعادة',
    'التطبيق': 'التمرين',
    'التحصيل': 'الفهم',
    'الاستيعاب': 'الفهم',

    // مصطلحات طبية
    'طيف التوحّد': 'التوحد',
    'اضطراب': 'حالة',
    'تشخيص': 'معرفة',
    'علاج': 'مساعدة',
    'تأهيل': 'تدريب',

    // مصطلحات نفسية
    'القلق': 'الخوف',
    'الاكتئاب': 'الحزن',
    'السلوك العدواني': 'العصبية',
    'التفاعل الاجتماعي': 'الكلام مع الناس',

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

  /// تقصير الجمل (حد أقصى 5 كلمات)
  String shorten(String text, {int maxWords = 5}) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')}...';
  }

  /// تبسيط + تقصير
  String process(String text) {
    return shorten(simplify(text));
  }
}