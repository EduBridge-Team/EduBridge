// لعبة بناء الكلمة — للأعمار 7-14
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/tts_service.dart';
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
  // كلمات متدرّجة حسب العمر
  static const _wordsByAge = {
    7: ['بيت', 'شمس', 'قمر', 'ماء', 'باب'],
    10: ['كتاب', 'مدرسة', 'شجرة', 'زهرة', 'سماء'],
    13: ['مكتبة', 'مستشفى', 'مطار', 'جامعة', 'مزرعة'],
  };

  late List<String> _words;
  late String _currentWord;
  late List<String> _scrambled;
  List<String> _userOrder = [];
  int _round = 0;
  int _score = 0;
  final _rnd = Random();

  int get _totalRounds => 6;

  @override
  void initState() {
    super.initState();
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
      _onWin();
      return;
    }
    _currentWord = _words[_rnd.nextInt(_words.length)];
    _scrambled = _currentWord.split('');
    // خلط الحروف
    do {
      _scrambled.shuffle(_rnd);
    } while (_scrambled.join() == _currentWord && _currentWord.length > 1);
    _userOrder = [];

    TtsService.instance.speakLine('رتّب الحروف لتكوين كلمة');
    setState(() {});
  }

  void _tapLetter(int index) {
    if (_userOrder.contains(_scrambled[index])) return;
    setState(() {
      _userOrder.add(_scrambled[index]);
    });
    if (_userOrder.length == _currentWord.length) {
      Future.delayed(const Duration(milliseconds: 300), _check);
    }
  }

  void _check() {
    final attempt = _userOrder.join();
    if (attempt == _currentWord) {
      setState(() {
        _score++;
        _round++;
      });
      TtsService.instance.speakLine('أحسنت! $_currentWord');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _newRound();
      });
    } else {
      setState(() => _userOrder = []);
      TtsService.instance.speakLine('حاول مرة أخرى');
    }
  }

  void _onWin() async {
    await VisualCelebration.show(
      context,
      message: 'أحسنت! $_score/$_totalRounds كلمات',
      emoji: '🔤',
      childName: widget.childName,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1AA9B2),
        foregroundColor: Colors.white,
        title: const Text('🔤 بناء الكلمة'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('الجولة: ${_round + 1}/$_totalRounds',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('النقاط: $_score ⭐',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('رتّب الحروف بالترتيب:',
              style: TextStyle(fontSize: 20, color: Colors.grey)),
          const SizedBox(height: 20),

          // الخانات الفارغة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: List.generate(_currentWord.length, (i) {
                final letter = i < _userOrder.length ? _userOrder[i] : '';
                return Container(
                  width: 55, height: 65,
                  decoration: BoxDecoration(
                    color: letter.isNotEmpty ? const Color(0xFF1AA9B2) : Colors.white,
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

          // الحروف
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12, runSpacing: 12,
              children: List.generate(_scrambled.length, (i) {
                final used = _userOrder.contains(_scrambled[i]);
                return GestureDetector(
                  onTap: used ? null : () => _tapLetter(i),
                  child: Opacity(
                    opacity: used ? 0.3 : 1,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1AA9B2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(_scrambled[i],
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}