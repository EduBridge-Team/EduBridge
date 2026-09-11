// لعبة الألوان
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/encouragement_service.dart';
import '../theme.dart';
import '../widgets/accessibility/visual_celebration.dart';

class ColorsGame extends StatefulWidget {
  final String childName;

  const ColorsGame({super.key, required this.childName});

  @override
  State<ColorsGame> createState() => _ColorsGameState();
}

class _ColorsGameState extends State<ColorsGame> {
  static const _colorData = [
    ('أحمر', Color(0xFFE53935)),
    ('أزرق', Color(0xFF1E88E5)),
    ('أخضر', Color(0xFF43A047)),
    ('أصفر', Color(0xFFFDD835)),
    ('بنفسجي', Color(0xFF8E24AA)),
    ('برتقالي', Color(0xFFFB8C00)),
  ];

  late List<(String, Color)> _options;
  late (String, Color) _target;
  int _score = 0;
  int _round = 0;
  int _streak = 0;
  static const _totalRounds = 8;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    if (_round >= _totalRounds) return;
    final rnd = Random();
    final shuffled = List<(String, Color)>.from(_colorData)..shuffle();
    _options = shuffled.take(4).toList();
    _target = _options[rnd.nextInt(_options.length)];
    EncouragementService.instance.praiseStart();
    setState(() {});
  }

  Future<void> _check((String, Color) option) async {
    if (option.$1 == _target.$1) {
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
      message: 'أنهيت اللعبة! $scorePercent%',
      emoji: '🌈',
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
            '🎨 أنت فنان!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'نتيجتك: $_score من $_totalRounds\n'
            'النسبة: $scorePercent%',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                ),
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

    return Scaffold(
      appBar: JisrAppBar(title: 'لعبة الألوان 🎨'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: c.tintGreen,
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Text(
                  'اختر اللون:',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  width: largeTargets ? 150 : 120,
                  height: largeTargets ? 150 : 120,
                  decoration: BoxDecoration(
                    color: _target.$2,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _target.$2.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _target.$1,
                  style: TextStyle(
                    fontSize: largeTargets ? 34 : 28,
                    fontWeight: FontWeight.bold,
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
                children: _options.map((option) {
                  return GestureDetector(
                    onTap: () => _check(option),
                    child: Container(
                      decoration: BoxDecoration(
                        color: option.$2,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: option.$2.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        option.$1,
                        style: TextStyle(
                          fontSize: largeTargets ? 28 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 4,
                            ),
                          ],
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