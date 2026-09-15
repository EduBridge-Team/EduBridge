// لعبة الرموز — لعمى الألوان
// الطفل يتعلّم الألوان بالاعتماد على الرموز والأنماط بدلاً من الألوان فقط
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/accessibility/visual_celebration.dart';

class SymbolsGame extends StatefulWidget {
  final String childName;

  const SymbolsGame({super.key, required this.childName});

  @override
  State<SymbolsGame> createState() => _SymbolsGameState();
}

class _SymbolsGameState extends State<SymbolsGame> {
  // كل رمز يحتوي على:
  // - symbol: الرمز (▲ ● ■ ★ ♦ ♥)
  // - name: اسم الشكل/اللون
  // - color: اللون الفعلي
    static const _symbols = [
    ('▲', 'مثلث', Color(0xFFE53935)),   // أحمر
    ('●', 'دائرة', Color(0xFF43A047)),  // أخضر
    ('■', 'مربع', Color(0xFF1E88E5)),   // أزرق
    ('★', 'نجمة', Color(0xFFFDD835)),   // أصفر
    ('♦', 'معين', Color(0xFFFB8C00)),   // برتقالي
    ('♥', 'قلب', Color(0xFF8E24AA)),    // بنفسجي
  ];
  
  late List<(String, String, Color)> _options;
  late (String, String, Color) _target;
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  final _rnd = Random();

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  int get _totalRounds => 8;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  // ═══════════════════════════════════════════════════════
  //  بدء جولة جديدة
  // ═══════════════════════════════════════════════════════
  void _newRound() {
    if (_round >= _totalRounds) {
      _onWin();
      return;
    }

    // خلط الرموز واختيار 4
    final shuffled = [..._symbols]..shuffle(_rnd);
    _options = shuffled.take(4).toList();

    // الهدف عشوائي من الخيارات
    _target = _options[_rnd.nextInt(_options.length)];

    // نطق الهدف
    _speak('أين ${_target.$2}؟');

    setState(() {});
  }

  void _speak(String text) {
    if (_profile.slowSpeech) {
      TtsService.instance.speakLineSlow(text);
    } else {
      TtsService.instance.speakLine(text);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  فحص الإجابة
  // ═══════════════════════════════════════════════════════
  Future<void> _check((String, String, Color) option) async {
    if (option.$2 == _target.$2) {
      // ✅ صحيح
      HapticFeedback.heavyImpact();
      setState(() {
        _score++;
        _streak++;
        _round++;
      });

      if (_streak >= 3) {
        _speak('رائع! ثلاث مرات متتالية');
      } else {
        _speak('أحسنت! ${option.$2}');
      }

      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) _newRound();
    } else {
      // ❌ خطأ
      HapticFeedback.mediumImpact();
      _speak('حاول مرة أخرى — انظر للرمز وليس اللون');

      setState(() => _streak = 0);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  عند الفوز
  // ═══════════════════════════════════════════════════════
  void _onWin() async {
    await VisualCelebration.show(
      context,
      message: 'أحسنت! $_score/$_totalRounds',
      emoji: '🌈',
      childName: widget.childName,
      duration: const Duration(seconds: 3),
    );
    if (mounted) Navigator.pop(context);
  }

  // ═══════════════════════════════════════════════════════
  //  واجهة المستخدم
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A6EA5),
        foregroundColor: Colors.white,
        title: const Text('🌈 لعبة الرموز'),
      ),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════
          //  شريط المعلومات
          // ═══════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip(
                  icon: '🎯',
                  label: 'الجولة',
                  value: '${_round + 1}/$_totalRounds',
                  color: const Color(0xFF3A6EA5),
                ),
                _infoChip(
                  icon: '⭐',
                  label: 'النقاط',
                  value: '$_score',
                  color: const Color(0xFF57B25A),
                ),
                if (_streak >= 2)
                  _infoChip(
                    icon: '🔥',
                    label: 'متتالية',
                    value: '$_streak',
                    color: const Color(0xFFF2842B),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════
          //  تنبيه تعليمي
          // ═══════════════════════════════════════════════
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A6EA5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3A6EA5).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF3A6EA5),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الرموز تساعدك على التمييز بدون الاعتماد على اللون فقط',
                    style: TextStyle(
                      fontSize: large ? 14 : 12,
                      color: const Color(0xFF3A6EA5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الهدف المطلوب
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'أين هذا الرمز؟',
                  style: TextStyle(
                    fontSize: large ? 22 : 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // عرض الهدف بشكل كبير
                Container(
                  width: large ? 200 : 170,
                  height: large ? 200 : 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3A6EA5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3A6EA5)
                            .withValues(alpha: 0.25),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _target.$1,
                        style: TextStyle(
                          fontSize: large ? 100 : 85,
                          color: _target.$3,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _target.$2,
                        style: TextStyle(
                          fontSize: large ? 22 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF12283A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الخيارات
          // ═══════════════════════════════════════════════
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: _options.map((option) {
                  return GestureDetector(
                    onTap: () => _check(option),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF3A6EA5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3A6EA5)
                                .withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // الرمز بلونه
                          Text(
                            option.$1,
                            style: TextStyle(
                              fontSize: large ? 68 : 56,
                              color: option.$3,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // الاسم
                          Text(
                            option.$2,
                            style: TextStyle(
                              fontSize: large ? 18 : 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF12283A),
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

  // ═══════════════════════════════════════════════════════
  //  رقاقة معلومات صغيرة
  // ═══════════════════════════════════════════════════════
  Widget _infoChip({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}