// لعبة لغة الإشارة — للأطفال الصمّ وضعاف السمع
// تعلّم الطفل ربط الحرف بإشارته
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../theme.dart';
import '../widgets/accessibility/visual_celebration.dart';

class SignLanguageGame extends StatefulWidget {
  final String childName;

  const SignLanguageGame({super.key, required this.childName});

  @override
  State<SignLanguageGame> createState() => _SignLanguageGameState();
}

class _SignLanguageGameState extends State<SignLanguageGame> {
  // ✅ بيانات تجريبية — يمكن استبدالها بصور لغة الإشارة الحقيقية
  // لكل حرف: (الحرف، الإيموجي التمثيلي، اسم الإشارة)
  static const _signData = [
    ('أ', '👍', 'إصبع الإبهام مرفوع'),
    ('ب', '✋', 'كف مفتوح مستقيم'),
    ('ت', '✌️', 'إصبعان مفتوحان'),
    ('ث', '🤟', 'ثلاثة أصابع'),
    ('ج', '👊', 'قبضة مغلقة'),
    ('ح', '🤙', 'الإبهام والخنصر'),
    ('خ', '👌', 'إصبعان متقاطعان'),
    ('د', '👆', 'إصبع واحد مرفوع'),
  ];

  late List<(String, String, String)> _options;
  late (String, String, String) _target;
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
    final shuffled =
        List<(String, String, String)>.from(_signData)..shuffle();
    _options = shuffled.take(4).toList();
    _target = _options[rnd.nextInt(_options.length)];

    // 📳 اهتزاز خفيف للإشارة بالبداية (بدل الصوت)
    HapticFeedback.lightImpact();
    setState(() {});
  }

  Future<void> _check((String, String, String) option) async {
    if (option.$1 == _target.$1) {
      // ✅ صحيح
      setState(() {
        _score++;
        _round++;
        _streak++;
      });

      // 📳 اهتزاز قوي عند الصحيح
      HapticFeedback.heavyImpact();

      if (_round >= _totalRounds) {
        await Future.delayed(const Duration(milliseconds: 300));
        _onWin();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        _newRound();
      }
    } else {
      // ❌ خطأ
      HapticFeedback.mediumImpact();
      setState(() => _streak = 0);
    }
  }

  Future<void> _onWin() async {
    final scorePercent = ((_score / _totalRounds) * 100).round();

    // 🎉 احتفال بصري ضخم (بدون صوت — للأصمّ)
    await VisualCelebration.show(
      context,
      message: 'أحسنت يا ${widget.childName}! $scorePercent%',
      emoji: '🤟',
      duration: const Duration(seconds: 4),
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🤟 بطل لغة الإشارة!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'النقاط: $_score/$_totalRounds',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                'النسبة: $scorePercent%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scorePercent >= 70
                      ? AppColors.greenDeep
                      : AppColors.orangeDeep,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
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

    return Scaffold(
      appBar: JisrAppBar(title: 'لعبة لغة الإشارة 🤟'),
      body: Column(
        children: [
          // شريط النقاط
          Container(
            padding: const EdgeInsets.all(14),
            color: c.tintTeal,
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

          // الحرف المطلوب + إشارته
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.pink, AppColors.orange],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'اختر الإشارة الصحيحة للحرف:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _target.$1,
                    style: const TextStyle(
                      fontSize: 90,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // الخيارات — إشارات
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
                        color: c.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.pink.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option.$2,
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8),
                            child: Text(
                              option.$3,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.muted,
                              ),
                            ),
                          ),
                        ],
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