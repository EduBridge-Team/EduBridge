// lib/services/tts_service.dart
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
  // هل يتم النطق حالياً؟ (اختياري)
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  // دالة تهيئة ثابتة تُستدعى من main.dart
  static Future<void> init() async {
    await instance._ensureInit();
  }

  // تهيئة المحرك الصوتي
  Future<void> _ensureInit() async {
    if (_ready) return;
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45);
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

  // نطق سطر معين
  Future<void> speakLine(String text) async {
    await _ensureInit();
    final t = text.trim();
    if (t.isEmpty) return;
    await _tts.stop();
    activeLine.value = text;
    isSpeaking.value = true;
    await _tts.speak(_normalizeArabic(t));
  }

  // إيقاف النطق فوراً
  Future<void> stop() async {
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
