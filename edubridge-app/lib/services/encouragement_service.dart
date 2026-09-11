// خدمة التشجيع الصوتي — عبارات حماسية بالعربية لكل حالة
import 'dart:math';
import 'tts_service.dart';

class EncouragementService {
  EncouragementService._();
  static final EncouragementService instance = EncouragementService._();

  final _random = Random();

  static const _successPhrases = [
    'أحسنت! أنت رائع 🌟',
    'ممتاز! استمر هكذا 💪',
    'عمل رائع! فخور بك 🎉',
    'بطل! أكملت المهمة بنجاح 🏆',
    'ما شاء الله عليك! ممتاز ✨',
    'رائع جداً! أنت تتقدم بسرعة 🚀',
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
    'قريب جداً! حاول ثانية 🌱',
    'أنت تتعلم! جرب من جديد ✨',
  ];

  static const _streakPhrases = [
    'واو! ثلاث مرات متتالية! أنت نجم 🌟🌟',
    'مذهل! تستمر في التألق 🔥',
    'لا يُوقفك شيء! أنت بطل حقيقي 🏆',
  ];

  // ✅ خاص بمتلازمة داون — كلمات بسيطة جداً + صوت بطيء
  static const _downPhrases = [
    'أنت بطل! 🏆',
    'ممتاز! ⭐',
    'أحسنت! 🎉',
    'رائع! 💪',
    'شاطر! 🌟',
  ];

  Future<void> praiseSuccess() async {
    final phrase = _successPhrases[_random.nextInt(_successPhrases.length)];
    await TtsService.instance.speakLine(phrase);
  }

  Future<void> praiseStart() async {
    final phrase = _startPhrases[_random.nextInt(_startPhrases.length)];
    await TtsService.instance.speakLine(phrase);
  }

  Future<void> praiseGame() async {
    final phrase = _gamePhrases[_random.nextInt(_gamePhrases.length)];
    await TtsService.instance.speakLine(phrase);
  }

  Future<void> gentleRetry() async {
    final phrase = _gentlePhrases[_random.nextInt(_gentlePhrases.length)];
    await TtsService.instance.speakLine(phrase);
  }

  Future<void> praiseStreak() async {
    final phrase = _streakPhrases[_random.nextInt(_streakPhrases.length)];
    await TtsService.instance.speakLine(phrase);
  }

  Future<void> praiseByName(String childName) async {
    final phrases = [
      'أحسنت يا $childName! أنت رائع 🌟',
      'ممتاز يا $childName! استمر 💪',
      'يا بطل يا $childName! عمل رائع 🏆',
      'ما شاء الله يا $childName! ✨',
    ];
    await TtsService.instance.speakLine(
      phrases[_random.nextInt(phrases.length)],
    );
  }

  /// ✅ للداون: كلمات بسيطة جداً + صوت بطيء
  Future<void> praiseForDown({String? childName}) async {
    final base = _downPhrases[_random.nextInt(_downPhrases.length)];
    final phrase = childName != null && childName.isNotEmpty
        ? '$childName، $base'
        : base;
    await TtsService.instance.speakLineSlow(phrase);
  }

  Future<void> praiseScore(int score) async {
    String phrase;
    if (score >= 90) {
      phrase = 'مذهل! $score نقطة! أنت عبقري 🏆';
    } else if (score >= 70) {
      phrase = 'رائع! $score نقطة! أحسنت 🌟';
    } else if (score >= 50) {
      phrase = 'جيد! $score نقطة! واصل 💪';
    } else {
      phrase = '$score نقطة! بداية جيدة، استمر 🌱';
    }
    await TtsService.instance.speakLine(phrase);
  }
}