// لعبة الأشكال — للأعمار 4-8
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

class ShapesGame extends StatefulWidget {
  final String childName;
  final int age;

  const ShapesGame({super.key, required this.childName, required this.age});

  @override
  State<ShapesGame> createState() => _ShapesGameState();
}

class _ShapesGameState extends State<ShapesGame> {
  static const _shapes = [
    ('🔺', 'مثلث', 3),
    ('🟦', 'مربع', 4),
    ('⚫', 'دائرة', 0),
    ('⭐', 'نجمة', 5),
    ('❤️', 'قلب', 0),
    ('⬡', 'سُدَاسي', 6),
  ];

  late List<(String, String, int)> _options;
  late (String, String, int) _target;
  int _round = 0;
  int _score = 0;
  final _rnd = Random();

  int get _totalRounds => widget.age <= 6 ? 5 : 8;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    if (_round >= _totalRounds) {
      _onWin();
      return;
    }
    final shuffled = [..._shapes]..shuffle();
    final count = widget.age <= 6 ? 3 : 4;
    _options = shuffled.take(count).toList();
    _target = _options[_rnd.nextInt(_options.length)];

    TtsService.instance.speakLine('أين ${_target.$2}؟');
    setState(() {});
  }

  void _check((String, String, int) option) {
    if (option.$2 == _target.$2) {
      setState(() {
        _score++;
        _round++;
      });
      TtsService.instance.speakLine('أحسنت! ${option.$2}');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _newRound();
      });
    } else {
      TtsService.instance.speakLine('حاول مرة أخرى');
    }
  }

  void _onWin() async {
    await VisualCelebration.show(
      context,
      message: 'أحسنت! $_score/$_totalRounds',
      emoji: '🔺',
      childName: widget.childName,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2842B),
        foregroundColor: Colors.white,
        title: const Text('🔺 لعبة الأشكال'),
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
          const SizedBox(height: 20),
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFF2842B), Color(0xFFFFC23C),
              ]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF2842B).withValues(alpha: 0.4),
                  blurRadius: 30, spreadRadius: 5,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(_target.$1, style: const TextStyle(fontSize: 110)),
          ),
          const SizedBox(height: 20),
          Text('أين ${_target.$2}؟',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16, crossAxisSpacing: 16,
                children: _options.map((option) {
                  return GestureDetector(
                    onTap: () => _check(option),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF2842B), width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(option.$1, style: const TextStyle(fontSize: 68)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}