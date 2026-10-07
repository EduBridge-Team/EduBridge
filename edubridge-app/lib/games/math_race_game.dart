// لعبة سباق الحساب — للأعمار 7-14
import 'dart:async';
import '../features/games/application/game_question_factory.dart';
import '../features/games/domain/arithmetic_question.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

class MathRaceGame extends StatefulWidget {
  final String childName;
  final int age;

  const MathRaceGame({super.key, required this.childName, required this.age});

  @override
  State<MathRaceGame> createState() => _MathRaceGameState();
}

class _MathRaceGameState extends State<MathRaceGame> {
  final _questions = GameQuestionFactory();
  late ArithmeticQuestion _question;
  late List<int> _options;
  int _score = 0;
  int _wrong = 0;
  int _timeLeft = 60;
  Timer? _timer;

  AccessibilityProfile get _profile => AccessibilityService.instance.profile.value;
  bool get _noPressure => _profile.noTimers || _profile.type == DisabilityType.adhd;

  @override
  void initState() {
    super.initState();
    _newQuestion();
    if (!_noPressure) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_timeLeft <= 1) {
          _timer?.cancel();
          _onFinish();
        } else {
          setState(() => _timeLeft--);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newQuestion() {
    _question = _questions.arithmetic(widget.age);
    _options = _questions.arithmeticChoices(_question);
  }

  Future<void> _check(int picked) async {
    if (picked == _question.answer) {
      setState(() => _score++);
      HapticFeedback.lightImpact();
      if (mounted) setState(() => _newQuestion());
    } else {
      setState(() => _wrong++);
      HapticFeedback.mediumImpact();
    }
  }

  void _onFinish() async {
    final totalAnswers = _score + _wrong;
    final scorePercent = totalAnswers == 0 ? 0 : ((_score / totalAnswers) * 100).round();
    await GameProgressService.instance.record(scorePercent);
    await VisualCelebration.show(
      context,
      message: '$_score صحيحة!',
      emoji: '➕',
      childName: widget.childName,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2842B),
        foregroundColor: Colors.white,
        title: const Text('➕ سباق الحساب'),
        actions: [
          if (_noPressure)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text('✅ بدون وقت',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('⭐ $_score',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('❌ $_wrong',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (!_noPressure)
                  Text('⏱️ $_timeLeft',
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: _timeLeft < 15 ? Colors.red : null,
                      )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(_question.expression,
                      style: const TextStyle(
                        fontSize: 64, fontWeight: FontWeight.bold,
                        color: Color(0xFF12283A),
                      ))),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 2,
              children: options.map((opt) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2842B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _check(opt),
                  child: Text('$opt',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
          ),
        ],
      ))))),
    );
  }
}