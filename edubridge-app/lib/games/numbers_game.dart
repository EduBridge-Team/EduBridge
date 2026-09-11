// لعبة الأرقام
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/encouragement_service.dart';
import '../theme.dart';
import '../widgets/accessibility/visual_celebration.dart';

class NumbersGame extends StatefulWidget {
  final String childName;

  const NumbersGame({super.key, required this.childName});

  @override
  State<NumbersGame> createState() => _NumbersGameState();
}

class _NumbersGameState extends State<NumbersGame> {
  int _score = 0;
  int _round = 0;
  int _streak = 0;
  static const _totalRounds = 8;

  late int _targetNumber;
  late List<int> _options;

  final _numberEmojis = ['🍎', '🍌', '🍇', '🍓', '🍊', '🥕'];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    if (_round >= _totalRounds) return;
    final rnd = Random();
    _targetNumber = 1 + rnd.nextInt(6);

    final set = <int>{_targetNumber};
    while (set.length < 4) {
      set.add(1 + rnd.nextInt(6));
    }
    _options = set.toList()..shuffle();

    EncouragementService.instance.praiseStart();
    setState(() {});
  }

  Future<void> _check(int number) async {
    if (number == _targetNumber) {
      setState(() {
        _score++;
        _round++;
        _streak++;
      });

      if (_streak == 3) {
        EncouragementService.instance.praiseStreak();
      } else {
        EncouragementService.instance.praiseSuccess();
      }

      if (_round >= _totalRounds) {
        _onWin();
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        _newRound();
      }
    } else {
      setState(() => _streak = 0);
      EncouragementService.instance.gentleRetry();
    }
  }

  Future<void> _onWin() async {
    final scorePercent = ((_score / _totalRounds) * 100).round();

    await VisualCelebration.show(
      context,
      message: 'أحسنت! $scorePercent%',
      emoji: '🔢',
      childName: widget.childName,
      duration: const Duration(seconds: 3),
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🔢 عبقري الأرقام!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'النقاط: $_score/$_totalRounds',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal),
                icon: const Icon(Icons.replay),
                label: const Text('العب من جديد'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _score = 0;
                    _round = 0;
                    _streak = 0;
                  });
                  _newRound();
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final profile = AccessibilityService.instance.profile.value;
    final largeTargets = profile.extraLargeTouchTargets;
    final rnd = Random();
    final emoji = _numberEmojis[rnd.nextInt(_numberEmojis.length)];

    return Scaffold(
      appBar: JisrAppBar(title: 'لعبة الأرقام 🔢'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: c.tintOrange,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Text(
                  'كم عدد؟',
                  style: TextStyle(fontSize: 22, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.line, width: 2),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      _targetNumber,
                      (_) => Text(
                        emoji,
                        style: TextStyle(
                          fontSize: largeTargets ? 54 : 42,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: _options.map((number) {
                  return GestureDetector(
                    onTap: () => _check(number),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: largeTargets ? 72 : 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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