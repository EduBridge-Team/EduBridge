import 'dart:math';
import '../l10n/generated/app_localizations.dart';
import 'app_locale_controller.dart';
import 'tts_service.dart';
import 'accessibility_service.dart';
import '../utils/adaptive_feedback_policy.dart';

class EncouragementService {
  EncouragementService({
    AccessibilityProfile Function()? profile,
    AppLocalizations Function()? strings,
    Future<void> Function(String)? speak,
    Future<void> Function(String)? speakSlow,
  }) : _profile = profile ?? (() => AccessibilityService.instance.profile.value),
       _strings = strings ?? (() => lookupAppLocalizations(AppLocaleController.instance.value)),
       _speak = speak, _speakSlow = speakSlow;

  static final EncouragementService instance = EncouragementService();
  final AccessibilityProfile Function() _profile;
  final AppLocalizations Function() _strings;
  final Future<void> Function(String)? _speak;
  final Future<void> Function(String)? _speakSlow;
  final _random = Random();

  Future<void> _announce(String text, AppLocalizations strings) async {
    final profile = _profile();
    if (!AdaptiveFeedbackPolicy(profile).allowAutomaticSpeech) return;
    final customSpeech = profile.slowSpeech ? _speakSlow : _speak;
    if (customSpeech != null) {
      await customSpeech(text);
    } else if (profile.slowSpeech) {
      await TtsService.instance.speakLineSlow(text, languageCode: strings.localeName);
    } else {
      await TtsService.instance.speakLine(text, languageCode: strings.localeName);
    }
  }

  Future<void> praiseSuccess() async {
    final s = _strings();
    final phrases = [
      s.encourageSuccess1,
      s.encourageSuccess2,
      s.encourageSuccess3,
      s.encourageSuccess4,
      s.encourageSuccess5,
      s.encourageSuccess6,
      s.encourageSuccess7,
    ];
    await _announce(phrases[_random.nextInt(phrases.length)], s);
  }

  Future<void> praiseStart() async {
    final s = _strings();
    final phrases = [
      s.encourageStart1,
      s.encourageStart2,
      s.encourageStart3,
    ];
    await _announce(phrases[_random.nextInt(phrases.length)], s);
  }

  Future<void> praiseGame() async {
    final s = _strings();
    final phrases = [
      s.encourageGame1,
      s.encourageGame2,
      s.encourageGame3,
    ];
    await _announce(phrases[_random.nextInt(phrases.length)], s);
  }

  Future<void> gentleRetry() async {
    final s = _strings();
    final phrases = [
      s.encourageGentle1,
      s.encourageGentle2,
      s.encourageGentle3,
    ];
    await _announce(phrases[_random.nextInt(phrases.length)], s);
  }

  Future<void> praiseStreak() async {
    final s = _strings();
    final phrases = [
      s.encourageStreak1,
      s.encourageStreak2,
      s.encourageStreak3,
    ];
    await _announce(phrases[_random.nextInt(phrases.length)], s);
  }

  Future<void> praiseByName(String childName) async {
    final s = _strings();
    final phrases = [
      s.encourageNamed1(childName),
      s.encourageNamed2(childName),
      s.encourageNamed3(childName),
      s.encourageNamed4(childName),
    ];
    await _announce(phrases[_random.nextInt(phrases.length)], s);
  }

  /// Saved preferences control speech and speed for legacy callers too.
  Future<void> praiseForDown({String? childName}) async {
    final s = _strings();
    final phrases = [
      s.encourageShort1,
      s.encourageShort2,
      s.encourageShort3,
      s.encourageShort4,
      s.encourageShort5,
    ];
    final base = phrases[_random.nextInt(phrases.length)];
    await _announce(childName != null && childName.isNotEmpty
      ? s.encourageNamedShort(childName, base) : base, s);
  }

  Future<void> praiseScore(int score) async {
    final s = _strings();
    final phrase = score >= 90 ? s.encourageScore1(score)
      : score >= 70 ? s.encourageScore2(score)
      : score >= 50 ? s.encourageScore3(score) : s.encourageScore4(score);
    await _announce(phrase, s);
  }
}
