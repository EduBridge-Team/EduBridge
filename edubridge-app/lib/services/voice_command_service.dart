// خدمة الأوامر الصوتية — للاعتماد على الصوت بدل اللمس
// تستخدم speech_to_text لالتقاط الأوامر، وتنفّذها عبر التنقل والإعدادات
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart'
    show SpeechRecognitionResult;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../games/audio_matching_game.dart';
import '../games/colors_game.dart';
import '../games/matching_game.dart';
import '../games/math_race_game.dart';
import '../games/numbers_game.dart';
import '../games/quick_action_game.dart';
import '../games/rhythm_game.dart';
import '../games/sequence_game.dart';
import '../games/shapes_game.dart';
import '../games/sign_language_game.dart';
import '../games/story_sequencer_game.dart';
import '../games/symbols_game.dart';
import '../games/visual_words_game.dart';
import '../games/word_builder_game.dart';
import '../screens/children_accessibility_overview_screen.dart';
import '../screens/children_screen.dart';
import '../screens/chats_screen.dart';
import '../screens/educational_games_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/assistant_screen.dart';
import '../theme.dart';
import '../utils/navigation.dart';
import 'accessibility_service.dart';
import 'tts_service.dart';

class VoiceCommandService {
  VoiceCommandService._();
  static final VoiceCommandService instance = VoiceCommandService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;

  /// هل المايك يسمع حالياً؟
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);

  /// آخر ما سمعه المايك (للعرض)
  final ValueNotifier<String> lastHeard = ValueNotifier<String>('');

  /// آخر ردّ فعلي من الخدمة
  final ValueNotifier<String> lastReply = ValueNotifier<String>('');

  bool get isAvailable => _available;

  // ═══════════════════════════════════════════════════════
  //  التهيئة
  // ═══════════════════════════════════════════════════════
  Future<bool> initialize() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      return _available;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      isListening.value = false;
    }
  }

  void _onError(dynamic error) {
    isListening.value = false;
  }

  // ═══════════════════════════════════════════════════════
  //  بدء الاستماع
  // ═══════════════════════════════════════════════════════
  Future<void> startListening() async {
    if (!await initialize()) {
      await _speak('الميكروفون غير متاح على هذا الجهاز');
      return;
    }

    if (isListening.value) {
      await stopListening();
      return;
    }

    await TtsService.instance.stop();

    lastHeard.value = '';
    lastReply.value = '';
    isListening.value = true;

    await _speech.listen(
      localeId: 'ar-SA',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      onResult: _onResult,
    );
  }

  Future<void> stopListening() async {
    if (!isListening.value) return;
    isListening.value = false;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    isListening.value = false;
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════
  //  معالجة النتيجة
  // ═══════════════════════════════════════════════════════
  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;

    lastHeard.value = text;

    if (result.finalResult) {
      _executeCommand(text);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  محرّك تنفيذ الأوامر
  // ═══════════════════════════════════════════════════════
  Future<void> _executeCommand(String rawText) async {
    final text = _normalize(rawText);
    final nav = appNavigatorKey.currentState;

    // ═══════════════════════════════════════════════════════
    //  1. أوامر القراءة
    // ═══════════════════════════════════════════════════════
    if (_matches(text, [
      'اقرا', 'اقراء', 'قراءه', 'قرايه',
      'شغل القراءه', 'فعل القراءه', 'ابدا القراءه', 'وضع القراءه',
    ])) {
      if (!TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply('وضع القراءة باللمس مُفعّل. المس أي عنصر وسأقرؤه لك');
      return;
    }

    if (_matches(text, ['اوقف القراءه', 'اقفل القراءه', 'الغ القراءه'])) {
      if (TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply('أوقفت وضع القراءة باللمس');
      return;
    }

    if (_matches(text, ['اوقف', 'اسكت', 'سكوت', 'هدوء'])) {
      await TtsService.instance.stop();
      await _reply('تم الإيقاف');
      return;
    }

    // ═══════════════════════════════════════════════════════
    //  2. التنقل
    // ═══════════════════════════════════════════════════════
    if (nav == null) {
      await _reply('تعذّر التنقل');
      return;
    }

    // ✅ شاشة الألعاب (قبل الألعاب المحددة — لأن "العب" عام)
    if (_matches(text, [
      'الالعاب', 'العاب', 'العب', 'لعبه', 'العبه', 'التعليميه',
      'افتح الالعاب', 'افتح العاب', 'قائمه الالعاب', 'شاشه الالعاب',
    ])) {
      // تحقق أنه ما طلب لعبة محددة
      final specificGame = _detectSpecificGame(text);
      if (specificGame == null) {
        await _reply('سأفتح شاشة الألعاب التعليمية');
        nav.push(MaterialPageRoute(
          builder: (_) => const EducationalGamesScreen(
            childName: 'بطل',
            age: 8,
          ),
        ));
        return;
      }
    }

    // ✅ ألعاب محددة بالاسم
    final gameId = _detectSpecificGame(text);
    if (gameId != null) {
      final widget = _gameWidgetFor(gameId);
      if (widget != null) {
        await _reply('سأفتح ${_gameDisplayName(gameId)}');
        nav.push(MaterialPageRoute(builder: (_) => widget));
        return;
      }
    }

    // ✅ الأطفال
    if (_matches(text, [
      'اطفال', 'الاطفال', 'الاولاد', 'اولاد', 'ولاد',
      'قائمه الاطفال', 'قائمة الاطفال',
    ])) {
      await _reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    // ✅ الدروس
    if (_matches(text, ['دروس', 'الدروس', 'درس'])) {
      await _reply('سأفتح الدروس');
      nav.push(MaterialPageRoute(builder: (_) => const LessonsScreen()));
      return;
    }

    // ✅ التقدّم
    if (_matches(text, [
      'تقدم', 'التقدم', 'انجاز', 'انجازات', 'الانجازات',
      'مكافات', 'نجوم', 'شارات',
    ])) {
      await _reply('سأفتح التقدّم');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenScreen(forProgress: true),
      ));
      return;
    }

    // ✅ الإشعارات
    if (_matches(text, [
      'اشعارات', 'الاشعارات', 'تنبيهات', 'تنبيه', 'جرس',
    ])) {
      await _reply('سأفتح الإشعارات');
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      return;
    }

    // ✅ المحادثات
    if (_matches(text, [
      'محادثات', 'المحادثات', 'محادثه', 'المحادثه',
      'رسائل', 'الرسائل', 'رساله', 'شات',
    ])) {
      await _reply('سأفتح المحادثات');
      nav.push(MaterialPageRoute(builder: (_) => const ChatsScreen()));
      return;
    }

    // ✅ المساعد
    if (_matches(text, [
      'مساعد', 'المساعد', 'نور', 'روبوت', 'ذكاء', 'اسال',
    ])) {
      await _reply('سأفتح المساعد نور');
      nav.push(MaterialPageRoute(builder: (_) => const AssistantScreen()));
      return;
    }

    // ✅ الاحتياجات
    if (_matches(text, [
      'احتياجات', 'الاحتياجات', 'اعدادات', 'الاعدادات',
      'تكييف', 'تخصيص',
    ])) {
      await _reply('سأفتح احتياجات الأبناء');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenAccessibilityOverviewScreen(),
      ));
      return;
    }

    // ✅ الرئيسية
    if (_matches(text, [
      'رئيسيه', 'الرئيسيه', 'رئيسي', 'الصفحه الاولى', 'البدايه', 'هوم',
    ])) {
      await _reply('سأرجع للرئيسية');
      nav.popUntil((r) => r.isFirst);
      return;
    }

    // ✅ ارجع
    if (_matches(text, ['ارجع', 'رجوع', 'للخلف', 'خلف', 'باك'])) {
      if (nav.canPop()) {
        nav.pop();
        await _reply('رجعت للخلف');
      } else {
        await _reply('لا يوجد شيء للرجوع');
      }
      return;
    }

    // ═══════════════════════════════════════════════════════
    //  3. الثيم
    // ═══════════════════════════════════════════════════════
    if (_matches(text, ['ليلي', 'الليلي', 'ظلام', 'داكن', 'مظلم'])) {
      await toggleThemeMode();
      await _reply('بدّلت للوضع الليلي');
      return;
    }

    if (_matches(text, ['فاتح', 'الفاتح', 'نهاري', 'نهار', 'صبح'])) {
      await toggleThemeMode();
      await _reply('بدّلت للوضع الفاتح');
      return;
    }

    // ═══════════════════════════════════════════════════════
    //  4. معلومات
    // ═══════════════════════════════════════════════════════
    if (_matches(text, [
      'مساعده', 'مساعدة', 'اوامر', 'الاوامر', 'شو بتعمل', 'شو تقدر',
    ])) {
      await _reply(
        'الأوامر المتاحة: افتح الدروس، الأطفال، الألعاب، التقدّم، '
        'الإشعارات، المحادثات، المساعد، الاحتياجات، اقرأ، أوقف، '
        'ارجع، الوضع الليلي. وتقدر تفتح أي لعبة مثل: لعبة الألوان، '
        'المطابقة، الأرقام، الأشكال، الإيقاع، والحركة السريعة',
      );
      return;
    }

    // ═══════════════════════════════════════════════════════
    //  5. لم أفهم
    // ═══════════════════════════════════════════════════════
    await _reply(
      'سمعتك تقول: $rawText. جرّب: افتح الألعاب، الدروس، الأطفال، أو اقرأ',
    );
  }

  // ═══════════════════════════════════════════════════════
  //  كشف اسم اللعبة المحددة من النص
  //  يُرجع id اللعبة أو null
  // ═══════════════════════════════════════════════════════
  String? _detectSpecificGame(String text) {
    // ⚠️ ترتيب الفحص مهم: الأكثر تخصيصاً أولاً

    // 🎵 الإيقاع
    if (_matches(text, ['ايقاع', 'الايقاع', 'نقر', 'طرق'])) {
      return 'rhythm';
    }

    // ⚡ الحركة السريعة
    if (_matches(text, ['حركه سريعه', 'الحركه السريعه', 'حركه', 'الح ركه', 'نشاط'])) {
      return 'quick';
    }

    // 🤟 لغة الإشارة
    if (_matches(text, ['اشاره', 'الاشاره', 'لغه الاشاره', 'الصم'])) {
      return 'sign';
    }

    // 📖 رتّب القصة
    if (_matches(text, ['قصه', 'القصه', 'رت ب', 'رت ب القصه', 'قصص'])) {
      return 'story';
    }

    // 🧩 الترتيب / التسلسل
    if (_matches(text, ['ترتيب', 'الترتيب', 'تسلسل', 'التسلسل'])) {
      return 'sequence';
    }

    // 🔤 بناء الكلمة
    if (_matches(text, ['بناء الكلمه', 'بناء كلمه', 'ابني كلمه', 'حروف'])) {
      return 'word_builder';
    }

    // 💙 الكلمات البصرية
    if (_matches(text, ['كلمات بصريه', 'الكلمات البصريه', 'كلمات', 'الكلمات'])) {
      return 'visual_words';
    }

    // ➕ سباق الحساب / الرياضيات
    if (_matches(text, ['حساب', 'الحساب', 'رياضيات', 'الرياضيات', 'سباق'])) {
      return 'math';
    }

    // 🔢 الأرقام / العد
    if (_matches(text, ['ارقام', 'الارقام', 'عدد', 'العد', 'رقم'])) {
      return 'numbers';
    }

    // 🌈 الرموز / عمى الألوان
    if (_matches(text, ['رموز', 'الرموز', 'عمي الالوان', 'نمط', 'انماط'])) {
      return 'symbols';
    }

    // 🎨 الألوان
    if (_matches(text, ['الوان', 'الالوان', 'لون', 'لوني'])) {
      return 'colors';
    }

    // 🔺 الأشكال
    if (_matches(text, ['اشكال', 'الاشكال', 'شكل', 'مربع', 'دايره', 'مثلث'])) {
      return 'shapes';
    }

    // 🎴 المطابقة
    if (_matches(text, ['مطابقه', 'المطابقه', 'اذواج', 'ازواج', 'بطاقات'])) {
      return 'matching';
    }

    // 🔊 لعبة الأصوات / أصوات الحيوانات
    if (_matches(text, [
      'اصوات', 'الاصوات', 'صوت', 'سمع', 'سمعيه', 'حيوانات صوتيه',
    ])) {
      return 'audio';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════
  //  إرجاع الـ widget المناسب لكل لعبة
  // ═══════════════════════════════════════════════════════
  Widget? _gameWidgetFor(String gameId) {
    const name = 'بطل';
    const age = 8;

    switch (gameId) {
      case 'audio':
        return const AudioMatchingGame(childName: name);
      case 'matching':
        return const MatchingGame(childName: name);
      case 'shapes':
        return const ShapesGame(childName: name, age: age);
      case 'colors':
        return const ColorsGame(childName: name);
      case 'symbols':
        return const SymbolsGame(childName: name);
      case 'numbers':
        return const NumbersGame(childName: name);
      case 'math':
        return const MathRaceGame(childName: name, age: age);
      case 'visual_words':
        return const VisualWordsGame(childName: name, age: age);
      case 'word_builder':
        return const WordBuilderGame(childName: name, age: age);
      case 'sequence':
        return const SequenceGame(childName: name);
      case 'story':
        return const StorySequencerGame(childName: name, age: age);
      case 'sign':
        return const SignLanguageGame(childName: name);
      case 'quick':
        return const QuickActionGame(childName: name);
      case 'rhythm':
        return const RhythmGame(childName: name);
      default:
        return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  //  اسم اللعبة للردّ الصوتي
  // ═══════════════════════════════════════════════════════
  String _gameDisplayName(String gameId) {
    switch (gameId) {
      case 'audio':
        return 'لعبة الأصوات';
      case 'matching':
        return 'لعبة المطابقة';
      case 'shapes':
        return 'لعبة الأشكال';
      case 'colors':
        return 'لعبة الألوان';
      case 'symbols':
        return 'لعبة الرموز';
      case 'numbers':
        return 'لعبة الأرقام';
      case 'math':
        return 'سباق الحساب';
      case 'visual_words':
        return 'الكلمات البصرية';
      case 'word_builder':
        return 'بناء الكلمة';
      case 'sequence':
        return 'لعبة الترتيب';
      case 'story':
        return 'رتّب القصة';
      case 'sign':
        return 'لغة الإشارة';
      case 'quick':
        return 'الحركة السريعة';
      case 'rhythm':
        return 'لعبة الإيقاع';
      default:
        return 'اللعبة';
    }
  }

  // ═══════════════════════════════════════════════════════
  //  أدوات مساعدة
  // ═══════════════════════════════════════════════════════

  /// تنظيف النص من التشكيل وتوحيد الألف والهمزات
  String _normalize(String input) {
    var t = input.trim();
    // إزالة التشكيل
    t = t.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    // إزالة التطويل
    t = t.replaceAll('\u0640', '');
    // توحيد الألف (أ إ آ ٱ → ا)
    t = t.replaceAll(RegExp('[أإآٱ]'), 'ا');
    // توحيد الهمزة (ئ → ي، ؤ → و)
    t = t.replaceAll('ئ', 'ي');
    t = t.replaceAll('ؤ', 'و');
    // توحيد الياء (ى → ي)
    t = t.replaceAll('ى', 'ي');
    // توحيد التاء المربوطة (ة → ه)
    t = t.replaceAll('ة', 'ه');
    // إزالة رموز الترقيم
    t = t.replaceAll(RegExp(r'[،.,!؟?]'), ' ');
    // توحيد المسافات
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// مطابقة مرنة
  bool _matches(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(_normalize(k))) return true;
    }
    return false;
  }

  Future<void> _reply(String message) async {
    lastReply.value = message;
    await TtsService.instance.speakLine(message);
  }

  Future<void> _speak(String message) async {
    await TtsService.instance.speakLine(message);
  }
}