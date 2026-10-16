// لعبة بناء الكلمة — للأعمار 7-14
import 'dart:math';
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
  late OrderedRound<String> _ordered;
  List<String> get _scrambled => _ordered.choices;
  List<String> get _userOrder => _ordered.selected;
  Set<int> get _usedIndices => _ordered.usedIndices;
  String? _feedback;
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
    _currentWord = GameContent.instance.pick('word_builder', _words, (word) => word);
    _ordered = OrderedRound(_currentWord.split(''), random: _rnd);

    _feedback = null;
    _answeredCorrectly = false;
    _speak('رتّب الحروف لتكوين كلمة');
    setState(() {});
  }

  void _speak(String text) {
    if (AdaptiveHelper.shouldReadOnTap) AdaptiveHelper.speak(text);
  }

  void _retry() {
    if (_finishing || _answeredCorrectly) return;
    setState(() {
      _ordered.reset();
      _feedback = null;
    });
    _speak('أعد المحاولة');
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
      _feedback = correct ? 'ممتاز! ترتيب صحيح' : 'خلينا نحاول مرة ثانية، رتّب حروف الكلمة';
      if (correct) _score++;
    });
    AdaptiveHelper.hapticFeedback();
    _speak(_feedback!);
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
      await VisualCelebration.show(context, message: 'أحسنت! $_score/$_totalRounds كلمات',
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
        title: const Text('🔤 بناء الكلمة'),
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
                Text('الجولة: ${_round + 1}/$_totalRounds',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('النقاط: $_score ⭐',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('كوّن كلمة: $_currentWord', textAlign: TextAlign.center,
              style: TextStyle(fontSize: large ? 28 : 22, fontWeight: FontWeight.bold)),
          TextButton.icon(onPressed: _finishing ? null : () => AdaptiveHelper.speak(_currentWord),
            icon: const Icon(Icons.volume_up_outlined), label: const Text('استمع للكلمة')),
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
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold,
                      color: letter.isNotEmpty ? Colors.white : Colors.grey,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 30),
          const Text('الحروف المتاحة:',
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
                      child: Text(_scrambled[i],
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_feedback != null)
            Semantics(liveRegion: true, child: Text(_feedback!, textAlign: TextAlign.center)),
          GameRoundContinuation(key: ValueKey(_round),
            answered: _answeredCorrectly, onContinue: _advance),
          if (_userOrder.isNotEmpty && !_answeredCorrectly)
            TextButton(onPressed: _finishing ? null : _retry,
              child: Text(_feedback == null ? 'أعد الترتيب' : 'حاول مرة أخرى')),
          const SizedBox(height: 20),
        ],
      )),
    );
  }
}