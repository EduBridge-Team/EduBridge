// خدمة القراءة الصوتية الشاملة — تعمل في كل مكان بكفاءة عالية
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static String _currentText = '';
  static bool _isSpeaking = false;

  /// وضع القراءة مفعّل
  static final ValueNotifier<bool> enabled = ValueNotifier(false);
   static String get currentText => _currentText;
  /// حالة التحدث الحالية — لعرض مؤشر جاري القراءة
  static final ValueNotifier<bool> isSpeaking = ValueNotifier(false);

  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      // ضبط اللغة والخصائص
      await _tts.setLanguage('ar');
      
      // سرعة القراءة — 0.4-0.5 للوضوح
      await _tts.setSpeechRate(0.4);
      
      // مستوى الصوت — الحد الأقصى
      await _tts.setVolume(1.0);
      
      // طبقة الصوت — عادية
      await _tts.setPitch(1.0);
      
      // عند انتهاء القراءة
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        isSpeaking.value = false;
      });
      
      // عند حدوث خطأ
      _tts.setErrorHandler((message) {
        debugPrint('TTS Error: $message');
        _isSpeaking = false;
        isSpeaking.value = false;
      });
      
      // عند البدء بالقراءة
      _tts.setStartHandler(() {
        _isSpeaking = true;
        isSpeaking.value = true;
      });
      
      _initialized = true;
      debugPrint('✅ TTS Service Initialized');
    } catch (e) {
      debugPrint('❌ TTS Init Error: $e');
    }
  }

  /// تبديل وضع القراءة — تفعيل/تعطيل
  static Future<void> toggle() async {
    await init();
    if (enabled.value) {
      await stop();
      enabled.value = false;
      debugPrint('📴 Reading Mode Disabled');
    } else {
      enabled.value = true;
      await speak('تم تفعيل وضع القراءة. اضغط على أي نص لسماعه.');
      debugPrint('📢 Reading Mode Enabled');
    }
  }

  /// قراءة نص — الدالة الرئيسية
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      debugPrint('⚠️ Empty text provided');
      return;
    }
    
    await init();
    
    // توقف أي قراءة سابقة
    await stop();
    
    _currentText = text.trim();
    _isSpeaking = true;
    isSpeaking.value = true;
    
    debugPrint('🔊 Starting to read: ${text.substring(0, 50)}...');
    
    try {
      // تقسيم النص إلى أجزاء قابلة للقراءة
      final chunks = _splitText(_currentText);
      debugPrint('📝 Text divided into ${chunks.length} chunks');
      
      for (int i = 0; i < chunks.length; i++) {
        if (!_isSpeaking) {
          debugPrint('⏹️ Reading stopped by user');
          break;
        }
        
        final chunk = chunks[i];
        debugPrint('📖 Reading chunk ${i + 1}/${chunks.length}');
        
        try {
          await _tts.speak(chunk);
          
          // انتظر قليلاً بين الأجزاء
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('❌ Error reading chunk: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ TTS Error: $e');
      _isSpeaking = false;
      isSpeaking.value = false;
    }
  }

  /// تقسيم النص الطويل إلى أجزاء
  static List<String> _splitText(String text) {
    const maxChunkLength = 500; // طول كل جزء
    final chunks = <String>[];
    
    if (text.length <= maxChunkLength) {
      chunks.add(text);
      return chunks;
    }
    
    // تقسيم حسب الجمل أولاً
    final sentences = text.split(RegExp(r'([.!?،؛]+)'));
    String currentChunk = '';
    
    for (int i = 0; i < sentences.length; i += 2) {
      final sentence = sentences[i];
      final punctuation = i + 1 < sentences.length ? sentences[i + 1] : '';
      final fullSentence = '$sentence$punctuation';
      
      if ((currentChunk + fullSentence).length > maxChunkLength) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = fullSentence;
      } else {
        currentChunk += fullSentence;
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }
    
    return chunks.where((c) => c.isNotEmpty).toList();
  }

  /// إيقاف القراءة فوراً
  static Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      isSpeaking.value = false;
      debugPrint('⏹️ Reading Stopped');
    } catch (e) {
      debugPrint('❌ Stop Error: $e');
    }
  }

  /// قراءة نص عند النقر — فقط إذا كان وضع القراءة مفعّلاً
  static Future<void> speakIfEnabled(String text) async {
    if (!enabled.value) return;
    await speak(text);
  }

  /// الحصول على حالة التحدث الحالية
  static bool get isCurrentlySpeaking => _isSpeaking;

  /// إعادة تهيئة الخدمة
  static Future<void> reinitialize() async {
    _initialized = false;
    await init();
  }
}