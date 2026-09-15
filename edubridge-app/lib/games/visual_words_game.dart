// لعبة الكلمات البصرية — لمتلازمة داون والإعاقة الذهنية
// الطفل يرى صورة ويكون عليه اختيار الكلمة الصحيحة من بين 4 خيارات
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

class VisualWordsGame extends StatefulWidget {
  final String childName;
  final int age;

  const VisualWordsGame({
    super.key,
    required this.childName,
    this.age = 8,
  });

  @override
  State<VisualWordsGame> createState() => _VisualWordsGameState();
}

class _VisualWordsGameState extends State<VisualWordsGame> {
  // ✅ سجلات موضعية (emoji, word)
  static const _words = [
    ('🍎', 'تفاحة'),
    ('🐶', 'كلب'),
    ('🏠', 'بيت'),
    ('☀️', 'شمس'),
    ('🌙', 'قمر'),
    ('🚗', 'سيارة'),
    ('🌳', 'شجرة'),
    ('🐟', 'سمكة'),
    ('📚', 'كتاب'),
    ('✏️', 'قلم'),
    ('🧸', 'دبدوب'),
    ('🚲', 'دراجة'),
  ];

  late (String, String) _target;
  late List<(String, String)> _options;
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  final _rnd = Random();

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  int get _totalRounds => 8;

  // عدد الخيارات حسب العمر
  int get _optionCount {
    if (widget.age <= 6) return 3;
    return 4;
  }

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

    // خلط الكلمات واختيار عدد مناسب
    final shuffled = [..._words]..shuffle(_rnd);
    _options = shuffled.take(_optionCount).toList();

    // الهدف عشوائي من الخيارات
    _target = _options[_rnd.nextInt(_options.length)];

    // ✅ نطق الكلمة بصوت بطيء للداون
    _speak('${_target.$2}');

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
  Future<void> _check((String, String) option) async {
    if (option.$2 == _target.$2) {
      // ✅ صحيح
      HapticFeedback.heavyImpact();
      setState(() {
        _score++;
        _streak++;
        _round++;
      });

      if (_streak >= 3) {
        _speak('رائع! ثلاث مرات متتالية!');
      } else {
        _speak('أحسنت! ${option.$2}');
      }

      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) _newRound();
    } else {
      // ❌ خطأ
      HapticFeedback.mediumImpact();
      _speak('حاول مرة أخرى — هذه ${option.$2}');

      setState(() => _streak = 0);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  عند الفوز
  // ═══════════════════════════════════════════════════════
  void _onWin() async {
    await VisualCelebration.show(
      context,
      message: 'أحسنت! $_score/$_totalRounds كلمات',
      emoji: '💙',
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
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF57B25A),
        foregroundColor: Colors.white,
        title: const Text('💙 الكلمات البصرية'),
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
                  color: const Color(0xFF57B25A),
                ),
                _infoChip(
                  icon: '⭐',
                  label: 'النقاط',
                  value: '$_score',
                  color: const Color(0xFFF2842B),
                ),
                if (_streak >= 2)
                  _infoChip(
                    icon: '🔥',
                    label: 'متتالية',
                    value: '$_streak',
                    color: const Color(0xFFE53935),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الصورة المطلوبة
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'ما هذه الصورة؟',
                  style: TextStyle(
                    fontSize: large ? 24 : 20,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // صورة كبيرة داخل دائرة
                Container(
                  width: large ? 220 : 190,
                  height: large ? 220 : 190,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF57B25A), Color(0xFF7BCF7E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF57B25A)
                            .withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _target.$1,
                    style: TextStyle(fontSize: large ? 130 : 115),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الخيارات (كلمات)
          // ═══════════════════════════════════════════════
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _optionCount == 3
                  ? _buildOptionsVertical(large)
                  : _buildOptionsGrid(large),
            ),
          ),
        ],
      ),
    );
  }

  // خيارات عمودية (3 خيارات — للأعمار الصغيرة)
  Widget _buildOptionsVertical(bool large) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _options.map((option) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: large ? 100 : 80,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF12283A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(
                    color: Color(0xFF57B25A),
                    width: 3,
                  ),
                ),
                elevation: 2,
              ),
              onPressed: () => _check(option),
              child: Text(
                option.$2,
                style: TextStyle(
                  fontSize: large ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF12283A),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // شبكة خيارات (4 خيارات — للأعمار الأكبر)
  Widget _buildOptionsGrid(bool large) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.3,
      children: _options.map((option) {
        return GestureDetector(
          onTap: () => _check(option),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF57B25A),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF57B25A).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              option.$2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: large ? 32 : 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF12283A),
              ),
            ),
          ),
        );
      }).toList(),
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