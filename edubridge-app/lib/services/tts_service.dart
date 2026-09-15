// lib/services/tts_service.dart
// خدمة النطق الصوتي — مع دعم سرعات متعددة بدون timers متصارعة
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  // وضع القراءة باللمس
  final ValueNotifier<bool> tapToRead = ValueNotifier<bool>(false);
  // السطر الجاري نطقه حالياً
  final ValueNotifier<String?> activeLine = ValueNotifier<String?>(null);
  // هل يتم النطق حالياً؟
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  // ✅ ثوابت السرعات — مصدر واحد للحقيقة
  static const double _normalRate = 0.45;
  static const double _slowRate = 0.30;

  // ✅ عدّاد أجيال: كل استدعاء نطق جديد يُبطِل ما قبله
  //    هذا يمنع أي سطر قديم من التأثير على السطر الحالي
  int _speakGeneration = 0;

  // دالة تهيئة ثابتة تُستدعى من main.dart
  static Future<void> init() async {
    await instance._ensureInit();
  }

  // تهيئة المحرك الصوتي
  Future<void> _ensureInit() async {
    if (_ready) return;
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(_normalRate);
    _tts.setCompletionHandler(() {
      activeLine.value = null;
      isSpeaking.value = false;
    });
    _tts.setCancelHandler(() {
      activeLine.value = null;
      isSpeaking.value = false;
    });
    _ready = true;
  }

  // تبديل وضع القراءة باللمس
  Future<void> toggleTapToRead() async {
    tapToRead.value = !tapToRead.value;
    if (!tapToRead.value) {
      activeLine.value = null;
      isSpeaking.value = false;
      await _tts.stop();
    }
  }

  /// ✅ الدالة الموحّدة للنطق — تُدار السرعة والعمر معاً
  ///    - تُبطِل أي طلب أقدم عبر عدّاد الأجيال
  ///    - تضبط السرعة قبل كل speak() — بدون Future.delayed
  Future<void> _speak(String text, {required double rate}) async {
    await _ensureInit();
    final t = text.trim();
    if (t.isEmpty) return;

    // كل استدعاء جديد يزيد العدّاد — الطلبات الأقدم تُعتبر ملغاة
    final generation = ++_speakGeneration;

    // إيقاف أي نطق جارٍ (قد يُشغّل cancelHandler — لا مشكلة)
    await _tts.stop();

    // لو وصل استدعاء أحدث أثناء stop() → لا نكمل
    if (generation != _speakGeneration) return;

    // ضبط السرعة قبل النطق مباشرة — لا timers، لا تخمين
    await _tts.setSpeechRate(rate);

    activeLine.value = text;
    isSpeaking.value = true;
    await _tts.speak(_normalizeArabic(t));
  }

  /// نطق عادي (سرعة 0.45) — للاستخدام العام
  Future<void> speakLine(String text) =>
      _speak(text, rate: _normalRate);

  /// نطق بطيء (سرعة 0.30) — لمتلازمة داون واضطرابات النطق
  Future<void> speakLineSlow(String text) =>
      _speak(text, rate: _slowRate);

  // إيقاف النطق فوراً — يُبطِل أي طلب جارٍ أيضاً
  Future<void> stop() async {
    _speakGeneration++; // إبطال أي _speak يعمل حالياً
    await _tts.stop();
    activeLine.value = null;
    isSpeaking.value = false;
  }

  // تحويل الأرقام الغربية إلى عربية ونطق النسب المئوية
  String _normalizeArabic(String input) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var out = input.replaceAll('%', ' بالمئة');
    for (var i = 0; i < western.length; i++) {
      out = out.replaceAll(western[i], arabic[i]);
    }
    return out;
  }
}