// خدمة التشجيع الصوتي — عبارات حماسية بالعربية لكل حالة
import 'dart:math';
import 'tts_service.dart';
import 'accessibility_service.dart';
import '../utils/adaptive_feedback_policy.dart';

class EncouragementService {
  EncouragementService({
    AccessibilityProfile Function()? profile,
    Future<void> Function(String)? speak,
    Future<void> Function(String)? speakSlow,
  }) : _profile = profile ?? (() => AccessibilityService.instance.profile.value),
       _speak = speak ?? TtsService.instance.speakLine,
       _speakSlow = speakSlow ?? TtsService.instance.speakLineSlow;

  static final EncouragementService instance = EncouragementService();
  final AccessibilityProfile Function() _profile;
  final Future<void> Function(String) _speak;
  final Future<void> Function(String) _speakSlow;

  Future<void> _announce(String text) async {
    final profile = _profile();
    if (!AdaptiveFeedbackPolicy(profile).allowAutomaticSpeech) return;
    await (profile.slowSpeech ? _speakSlow(text) : _speak(text));
  }

  final _random = Random();

  static const _successPhrases = [
    'أحسنت! أنت رائع 🌟',
    'ممتاز! استمر هكذا 💪',
    'عمل رائع! فخور بك 🎉',
    'بطل! أكملت المهمة بنجاح 🏆',
    'ما شاء الله عليك! ممتاز ✨',
    'أحسنت على جهودك! خذ وقتك 🌱',
    'إنجاز جميل! واصل التقدم 🌈',
  ];

  static const _startPhrases = [
    'هيا بنا نبدأ! أنا معك 🎯',
    'استعد! سنتعلم شيئاً جديداً 📚',
    'لنبدأ الرحلة! ستنجح بإذن الله 🌟',
  ];

  static const _gamePhrases = [
    'وقت المرح! هيا نلعب 🎮',
    'لعبة جديدة! استمتع 🌈',
    'هيا نلعب ونتعلم معاً 🎉',
  ];

  static const _gentlePhrases = [
    'لا بأس، جرب مرة أخرى 💙',
    'خذ وقتك، يمكنك المحاولة ثانية 🌱',
    'أنت تتعلم! جرب من جديد ✨',
  ];

  static const _streakPhrases = [
    'واو! ثلاث مرات متتالية! أنت نجم 🌟🌟',
    'مذهل! تستمر في التألق 🔥',
    'أحسنت على مواصلة المحاولة 🌟',
  ];

  // عبارات قصيرة يمكن استعمالها دون فرض سرعة النطق من التصنيف.
  static const _downPhrases = [
    'أنت بطل! 🏆',
    'ممتاز! ⭐',
    'أحسنت! 🎉',
    'رائع! 💪',
    'شاطر! 🌟',
  ];

  Future<void> praiseSuccess() async {
    final phrase = _successPhrases[_random.nextInt(_successPhrases.length)];
    await _announce(phrase);
  }

  Future<void> praiseStart() async {
    final phrase = _startPhrases[_random.nextInt(_startPhrases.length)];
    await _announce(phrase);
  }

  Future<void> praiseGame() async {
    final phrase = _gamePhrases[_random.nextInt(_gamePhrases.length)];
    await _announce(phrase);
  }

  Future<void> gentleRetry() async {
    final phrase = _gentlePhrases[_random.nextInt(_gentlePhrases.length)];
    await _announce(phrase);
  }

  Future<void> praiseStreak() async {
    final phrase = _streakPhrases[_random.nextInt(_streakPhrases.length)];
    await _announce(phrase);
  }

  Future<void> praiseByName(String childName) async {
    final phrases = [
      'أحسنت يا $childName! أنت رائع 🌟',
      'ممتاز يا $childName! استمر 💪',
      'يا بطل يا $childName! عمل رائع 🏆',
      'ما شاء الله يا $childName! ✨',
    ];
    await _announce(
      phrases[_random.nextInt(phrases.length)],
    );
  }

  /// Kept for existing callers; saved preferences control speech and speed.
  Future<void> praiseForDown({String? childName}) async {
    final base = _downPhrases[_random.nextInt(_downPhrases.length)];
    final phrase = childName != null && childName.isNotEmpty
        ? '$childName، $base'
        : base;
    await _announce(phrase);
  }

  Future<void> praiseScore(int score) async {
    String phrase;
    if (score >= 90) {
      phrase = 'مذهل! $score نقطة! أحسنت على جهودك 🏆';
    } else if (score >= 70) {
      phrase = 'رائع! $score نقطة! أحسنت 🌟';
    } else if (score >= 50) {
      phrase = 'جيد! $score نقطة! واصل 💪';
    } else {
      phrase = '$score نقطة! بداية جيدة، استمر 🌱';
    }
    await _announce(phrase);
  }
}