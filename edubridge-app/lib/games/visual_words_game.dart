// لعبة الكلمات البصرية — لمتلازمة داون والإعاقة الذهنية
// الطفل يرى صورة ويكون عليه اختيار الكلمة الصحيحة من بين 4 خيارات
import 'game_content.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessibility/visual_celebration.dart';
import '../widgets/accessibility/game_stat_chip.dart';
import '../widgets/accessibility/game_round_continuation.dart';
part 'visual_words_game_view.dart';

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
    ('🍌', 'موز'), ('🍇', 'عنب'), ('🌸', 'زهرة'), ('🐘', 'فيل'),
    ('🐢', 'سلحفاة'), ('🦋', 'فراشة'), ('✈️', 'طائرة'), ('🚂', 'قطار'),
    ('⚽', 'كرة'), ('🔑', 'مفتاح'), ('⏰', 'ساعة'), ('🥕', 'جزر'),
  ];

  late (String, String) _target;
  late List<(String, String)> _options;
  int _round = 0;
  bool _transitioning = false;
  int _score = 0;
  bool _resultRecorded = false;
  int _streak = 0;

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  int get _totalRounds => 8;

  // عدد الخيارات حسب العمر
  int get _optionCount {
    if (widget.age <= 6) return 3;
    return 4;
  }

  int get _roundNumber => _round >= _totalRounds
      ? _totalRounds : _round + (_transitioning ? 0 : 1);

  Future<void> _advance() async {
    if (!mounted || !_transitioning) return;
    if (_round >= _totalRounds) {
      await _onWin();
    } else {
      _newRound();
    }
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
    if (!mounted) return;
    if (_round >= _totalRounds) return;

    _transitioning = false;

    // خلط الكلمات واختيار عدد مناسب
    _target = GameContent.instance.pick('visual_words', _words, (item) => item.$2);
    final distractors = [..._words]..remove(_target)..shuffle();
    _options = [_target, ...distractors.take(_optionCount - 1)]..shuffle();

    // ✅ نطق الكلمة بصوت بطيء للداون
    _speak(_target.$2);

    setState(() {});
  }

  void _speak(String text) {
    if (AdaptiveHelper.shouldReadOnTap) AdaptiveHelper.speak(text);
  }

  // ═══════════════════════════════════════════════════════
  //  فحص الإجابة
  // ═══════════════════════════════════════════════════════
  void _check((String, String) option) {
    if (_transitioning) return;
    if (option.$2 == _target.$2) {
      _transitioning = true;
      // ✅ صحيح
      AdaptiveHelper.hapticFeedback();
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

    } else {
      // ❌ خطأ
      AdaptiveHelper.hapticFeedback();
      _speak('حاول مرة أخرى — هذه ${option.$2}');

      setState(() => _streak = 0);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  عند الفوز
  // ═══════════════════════════════════════════════════════
  Future<void> _onWin() async {
    if (!mounted || _resultRecorded) return;
    _resultRecorded = true;
    await GameProgressService.instance.record(((_score / _totalRounds) * 100).round());
    if (!mounted) return;
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
  Widget build(BuildContext context) => buildView(context);

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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.3 / MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
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

}