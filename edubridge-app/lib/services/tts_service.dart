// خدمة القراءة الصوتية العامة — تفعيل/إيقاف من زر واحد، ثم النقر على أي نص
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  /// وضع القراءة مفعّل — عند true يمكن النقر على النصوص لقراءتها
  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {});
    _initialized = true;
  }

  static Future<void> toggle() async {
    await init();
    if (enabled.value) {
      await stop();
      enabled.value = false;
    } else {
      enabled.value = true;
      await speak('تم تفعيل وضع القراءة. اضغط على أي نص لسماعه.');
    }
  }

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(text.trim());
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  /// قراءة نص عند النقر — فقط إذا كان وضع القراءة مفعّلاً
  static Future<void> speakIfEnabled(String text) async {
    if (!enabled.value) return;
    await speak(text);
  }
}
