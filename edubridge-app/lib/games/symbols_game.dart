// لعبة الرموز — لعمى الألوان
// الطفل يتعلّم الألوان بالاعتماد على الرموز والأنماط بدلاً من الألوان فقط
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';
part 'symbols_game_view.dart';

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
  Widget build(BuildContext context) => buildView(context);

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