// لعبة بناء الكلمة — للأعمار 7-14
import 'dart:math';
import '../l10n/l10n.dart';
import '../services/tts_service.dart';
import '../utils/ordered_game_display.dart';
import 'game_content.dart';
import '../features/games/domain/ordered_round.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/game_progress_service.dart';
import '../services/accessibility_service.dart';
import '../utils/adaptive_helper.dart';

import '../widgets/accessibility/game_round_continuation.dart';
import '../widgets/accessibility/visual_celebration.dart';

class WordBuilderGame extends StatefulWidget {
  final String childName;
  final int age;

  const WordBuilderGame({
    super.key,
    required this.childName,
    required this.age,
  });

  @override
  State<WordBuilderGame> createState() => _WordBuilderGameState();
}

class _WordBuilderGameState extends State<WordBuilderGame> {
  static const _wordsByAge = {
    7: ['بيت', 'شمس', 'قمر', 'ماء', 'باب', 'قلم', 'ورد', 'بحر', 'نجم', 'تمر', 'خبز', 'نهر'],
    10: ['كتاب', 'مدرسة', 'شجرة', 'زهرة', 'سماء', 'تفاحة', 'سيارة', 'نافذة', 'حقيبة', 'حديقة', 'طائرة', 'دراجة'],
    13: ['مكتبة', 'مستشفى', 'مطار', 'جامعة', 'مزرعة', 'موسيقى', 'رياضة', 'مهندس', 'معلمة', 'مختبر', 'مسرحية', 'مسابقة'],
  };

  late List<String> _words;
  late String _currentWord;
  late String _wordId;
  String? _wordLocale;

  String get _feedbackText => _feedback == true
      ? context.l10n.sequenceCorrect : context.l10n.wordBuilderIncorrect;

  void _localizeWord() {
    _currentWord = OrderedGameDisplay.word(_wordId, context.l10n);
    _ordered = OrderedRound(_currentWord.split(''), random: _rnd);
    if (_answeredCorrectly) {
      for (final letter in _currentWord.split('')) {
        _ordered.selectValue(letter);
      }
    } else {
      _feedback = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.l10n.localeName;
    if (_wordLocale != locale) {
      _wordLocale = locale;
      _localizeWord();
      _speak(context.l10n.wordBuilderInstruction);
    }
  }
  late OrderedRound<String> _ordered;
  List<String> get _scrambled => _ordered.choices;
  List<String> get _userOrder => _ordered.selected;
  Set<int> get _usedIndices => _ordered.usedIndices;
  bool? _feedback;
  bool _answeredCorrectly = false;
  bool _finishing = false;
  bool _recorded = false;
  int _round = 0;
  int _score = 0;
  final _rnd = Random();

  AccessibilityProfile get _profile => AccessibilityService.instance.profile.value;

  int get _totalRounds => 6;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.profile.addListener(_profileChanged);
    _words = _pickWordsForAge();
    _newRound();
  }

  List<String> _pickWordsForAge() {
    if (widget.age <= 8) return _wordsByAge[7]!;
    if (widget.age <= 11) return _wordsByAge[10]!;
    return _wordsByAge[13]!;
  }

  void _newRound() {
    if (_round >= _totalRounds) {
      return;
    }
    _wordId = GameContent.instance.pick('word_builder', _words, (word) => word);

    _feedback = null;
    _answeredCorrectly = false;
    if (_wordLocale != null) {
      _localizeWord();
      _speak(context.l10n.wordBuilderInstruction);
    }
    setState(() {});
  }

  void _speak(String text) {
    if (!AdaptiveHelper.shouldReadOnTap) return;
    _read(text);
  }

  void _read(String text) {
    final language = context.l10n.localeName;
    if (AdaptiveHelper.useSlowSpeech) {
      TtsService.instance.speakLineSlow(text, languageCode: language);
    } else {
      TtsService.instance.speakLine(text, languageCode: language);
    }
  }

  void _retry() {
    if (_finishing || _answeredCorrectly) return;
    setState(() {
      _ordered.reset();
      _feedback = null;
    });
    _speak(context.l10n.retry);
  }

  @override
  void dispose() {
    AccessibilityService.instance.profile.removeListener(_profileChanged);
    super.dispose();
  }

  void _profileChanged() {
    if (mounted) setState(() {});
  }


  void _tapLetter(int index) {
    // ✅ إصلاح: التحقق بالـ index وليس بالقيمة
    if (_finishing || _feedback != null || _ordered.complete || _usedIndices.contains(index)) return;
    setState(() {
      _ordered.selectIndex(index);
    });
    if (_userOrder.length == _currentWord.length) {
      _check();
    }
  }

  void _check() {
    if (!mounted || !_ordered.complete || _feedback != null) return;
    final correct = _ordered.correct;
    setState(() {
      _answeredCorrectly = correct;
      _feedback = correct;
      if (correct) _score++;
    });
    AdaptiveHelper.hapticFeedback();
    _speak(_feedbackText);
  }

  Future<void> _advance() async {
    if (!_answeredCorrectly || _finishing) return;
    if (_round + 1 >= _totalRounds) {
      await _onWin();
    } else {
      setState(() => _round++);
      _newRound();
    }
  }

  Future<void> _onWin() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      if (!_recorded) {
        await GameProgressService.instance.record(((_score / _totalRounds) * 100).round());
        _recorded = true;
      }
      if (!mounted) return;
      await VisualCelebration.show(context, message: context.l10n.wordBuilderComplete(_score, _totalRounds),
        emoji: '🔤', childName: widget.childName, duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _finishing = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FA),
      appBar: BrandAppBar(
        title: Text(context.l10n.wordBuilderTitle),
      ),
      body: SingleChildScrollView(child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(context.l10n.orderedGameRound(_round + 1, _totalRounds),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(context.l10n.orderedGameScore(_score),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(context.l10n.wordBuilderTarget(_currentWord), textAlign: TextAlign.center,
              style: TextStyle(fontSize: large ? 28 : 22, fontWeight: FontWeight.bold)),
          TextButton.icon(onPressed: _finishing ? null : () => _read(_currentWord),
            icon: const Icon(Icons.volume_up_outlined), label: Text(context.l10n.wordBuilderListen)),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: List.generate(_currentWord.length, (i) {
                final letter = i < _userOrder.length ? _userOrder[i] : '';
                return Container(
                  width: large ? 88 : 55, height: large ? 88 : 65,
                  decoration: BoxDecoration(
                    color: letter.isNotEmpty
                        ? const Color(0xFF1AA9B2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1AA9B2), width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold,
                      color: letter.isNotEmpty ? Colors.white : Colors.grey,
                    ),
                  )),
                );
              }),
            ),
          ),
          const SizedBox(height: 30),
          Text(context.l10n.wordBuilderLetters,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12, runSpacing: 12,
              children: List.generate(_scrambled.length, (i) {
                // ✅ إصلاح: التحقق بالـ index
                final used = _usedIndices.contains(i);
                return GestureDetector(
                  key: ValueKey('word_choice_$i'),
                  onTap: used ? null : () => _tapLetter(i),
                  child: Opacity(
                    opacity: used ? 0.3 : 1,
                    child: Container(
                      width: large ? 88 : 60, height: large ? 88 : 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF1AA9B2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(_scrambled[i],
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold))),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_feedback != null)
            Semantics(liveRegion: true, child: Text(_feedbackText, textAlign: TextAlign.center)),
          GameRoundContinuation(key: ValueKey(_round),
            answered: _answeredCorrectly, onContinue: _advance),
          if (_userOrder.isNotEmpty && !_answeredCorrectly)
            TextButton(onPressed: _finishing ? null : _retry,
              child: Text(_feedback == null ? context.l10n.sequenceReorder : context.l10n.retry)),
          const SizedBox(height: 20),
        ],
      )),
    );
  }
}