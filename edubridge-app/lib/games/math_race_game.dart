// لعبة سباق الحساب — للأعمار 7-14
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../theme.dart';
import '../widgets/accessibility/visual_celebration.dart';

class MathRaceGame extends StatefulWidget {
  final String childName;
  final int age;

  const MathRaceGame({super.key, required this.childName, required this.age});

  @override
  State<MathRaceGame> createState() => _MathRaceGameState();
}

class _MathRaceGameState extends State<MathRaceGame> {
  late int _a, _b;
  late String _op;
  late int _answer;
  int _score = 0;
  int _wrong = 0;
  int _timeLeft = 60;
  Timer? _timer;
  final _rnd = Random();

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
    if (widget.age <= 8) {
      _a = 1 + _rnd.nextInt(10);
      _b = 1 + _rnd.nextInt(10);
      _op = '+';
      _answer = _a + _b;
    } else if (widget.age <= 11) {
      if (_rnd.nextBool()) {
        _a = 5 + _rnd.nextInt(20);
        _b = 1 + _rnd.nextInt(15);
        _op = '+';
        _answer = _a + _b;
      } else {
        _a = 10 + _rnd.nextInt(20);
        _b = 1 + _rnd.nextInt(10);
        _op = '-';
        _answer = _a - _b;
      }
    } else {
      final ops = ['+', '-', '×'];
      _op = ops[_rnd.nextInt(ops.length)];
      if (_op == '×') {
        _a = 2 + _rnd.nextInt(10);
        _b = 2 + _rnd.nextInt(10);
        _answer = _a * _b;
      } else if (_op == '+') {
        _a = 20 + _rnd.nextInt(80);
        _b = 10 + _rnd.nextInt(50);
        _answer = _a + _b;
      } else {
        _a = 30 + _rnd.nextInt(70);
        _b = 5 + _rnd.nextInt(25);
        _answer = _a - _b;
      }
    }
  }

  List<int> _generateOptions() {
    final opts = <int>{_answer};
    while (opts.length < 4) {
      final diff = _rnd.nextInt(10) - 5;
      final fake = _answer + diff;
      if (fake > 0 && fake != _answer) opts.add(fake);
    }
    final list = opts.toList()..shuffle();
    return list;
  }

  Future<void> _check(int picked) async {
    if (picked == _answer) {
      setState(() => _score++);
      HapticFeedback.lightImpact();
      if (mounted) setState(() => _newQuestion());
    } else {
      setState(() => _wrong++);
      HapticFeedback.mediumImpact();
    }
  }

  void _onFinish() async {
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
    final options = _generateOptions();
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
      body: Column(
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
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$_a $_op $_b = ?',
                      style: const TextStyle(
                        fontSize: 64, fontWeight: FontWeight.bold,
                        color: Color(0xFF12283A),
                      )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              shrinkWrap: true,
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
      ),
    );
  }
}