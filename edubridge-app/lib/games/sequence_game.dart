// لعبة التسلسل والترتيب — للتوحّد والإعاقة الذهنية
// الطفل يرى 3 صور مبعثرة ويجب أن يرتّبها حسب الترتيب الصحيح
import 'dart:math';
import 'game_content.dart';
import '../features/games/domain/ordered_round.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessibility/game_round_continuation.dart';
import '../utils/adaptive_feedback_policy.dart';
import '../widgets/accessibility/visual_celebration.dart';

part 'sequence_game_view.dart';

class SequenceGame extends StatefulWidget {
  final String childName;

  const SequenceGame({super.key, required this.childName});

  @override
  State<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<SequenceGame> {
  // ✅ 5 تسلسلات بسيطة (3 بطاقات لكل واحدة)
  static const _sequences = [
    (
      emojis: ['🌅', '☀️', '🌙'],
      title: 'الصباح → الظهر → الليل',
      labels: ['الصباح', 'الظهر', 'الليل'],
    ),
    (
      emojis: ['🥚', '🐣', '🐔'],
      title: 'البيضة → الكتكوت → الدجاجة',
      labels: ['البيضة', 'الكتكوت', 'الدجاجة'],
    ),
    (
      emojis: ['🌱', '🌿', '🌳'],
      title: 'البذرة → النبتة → الشجرة',
      labels: ['البذرة', 'النبتة', 'الشجرة'],
    ),
    (
      emojis: ['1️⃣', '2️⃣', '3️⃣'],
      title: 'الترتيب العددي',
      labels: ['واحد', 'اثنان', 'ثلاثة'],
    ),
    (
      emojis: ['🍎', '🍽️', '😋'],
      title: 'التفاحة → الطبق → الأكل',
      labels: ['التفاحة', 'الطبق', 'الأكل'],
    ),
    (
      emojis: ['🧼', '💧', '✋'],
      title: 'الصابون → الماء → اليد',
      labels: ['الصابون', 'الماء', 'اليد'],
    ),
  ];

  late OrderedRound<String> _ordered;
  List<String> get _shuffled => _ordered.choices;
  late List<String> _correctOrder;
  late List<String> _correctLabels;
  late String _hint;
  String? _feedback;
  bool _answeredCorrectly = false;
  bool _finishing = false;
  bool _recorded = false;
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  List<String> get _userOrder => _ordered.selected;
  final _rnd = Random();

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  int get _totalRounds => 5;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.profile.addListener(_profileChanged);
    _newRound();
  }

  // ═══════════════════════════════════════════════════════
  //  بدء جولة جديدة
  // ═══════════════════════════════════════════════════════
  void _newRound() {
    if (_round >= _totalRounds) {
      return;
    }

    final seq = GameContent.instance.pick('sequences', _sequences, (item) => item.title);
    _correctOrder = List<String>.from(seq.emojis);
    _correctLabels = List<String>.from(seq.labels);
    _hint = seq.title;

    _ordered = OrderedRound(_correctOrder, random: _rnd);

    _feedback = null;
    _answeredCorrectly = false;

    // ✅ نطق التعليمات
    _speak('رتّب: $_hint');

    setState(() {});
  }

  void _speak(String text) {
    if (AdaptiveHelper.shouldReadOnTap) AdaptiveHelper.speak(text);
  }

  void _retry() {
    if (_finishing || _answeredCorrectly) return;
    setState(() {
      _ordered.reset();
      _feedback = null;
    });
    _speak('أعد المحاولة');
  }

  @override
  void dispose() {
    AccessibilityService.instance.profile.removeListener(_profileChanged);
    super.dispose();
  }

  void _profileChanged() {
    if (mounted) setState(() {});
  }


  // ═══════════════════════════════════════════════════════
  //  ضغط على بطاقة
  // ═══════════════════════════════════════════════════════
  void _tapEmoji(String emoji) {
    if (_finishing || _feedback != null || _ordered.complete || _userOrder.contains(emoji)) return;

    AdaptiveHelper.hapticFeedback();
    setState(() => _ordered.selectValue(emoji));

    if (_userOrder.length == _correctOrder.length) {
      _check();
    }
  }

  // ═══════════════════════════════════════════════════════
  //  فحص الترتيب
  // ═══════════════════════════════════════════════════════
  void _check() {
    if (!mounted || !_ordered.complete || _feedback != null) return;
    final correct = _ordered.correct;
    setState(() {
      _answeredCorrectly = correct;
      _feedback = correct ? 'ممتاز! ترتيب صحيح' : 'خلينا نحاول مرة ثانية، فكّر بترتيب الأحداث';
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
    AdaptiveHelper.hapticFeedback();
    _speak(_feedback!);
  }

  Future<void> _advance() async {
    if (!_answeredCorrectly || _finishing) return;
    if (_round + 1 >= _totalRounds) {
      await _onWin();
    } else {
      setState(() => _round++);
      _newRound();
    }
  }

  // ═══════════════════════════════════════════════════════
  Future<void> _onWin() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      if (!_recorded) {
        await GameProgressService.instance.record(((_score / _totalRounds) * 100).round());
        _recorded = true;
      }
      if (!mounted) return;
      await VisualCelebration.show(context, message: 'أحسنت! $_score/$_totalRounds',
        emoji: '🧩', childName: widget.childName, duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _finishing = false);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  //  واجهة المستخدم
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => _buildGame(context);
}
