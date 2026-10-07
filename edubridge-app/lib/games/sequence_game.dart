// لعبة التسلسل والترتيب — للتوحّد والإعاقة الذهنية
// الطفل يرى 3 صور مبعثرة ويجب أن يرتّبها حسب الترتيب الصحيح
import 'dart:math';
import 'game_content.dart';
import '../features/games/domain/ordered_round.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
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

    final seq = GameContent.instance.pick('sequences', _sequences, (item) => item.title);
    _correctOrder = List<String>.from(seq.emojis);
    _correctLabels = List<String>.from(seq.labels);
    _hint = seq.title;

    _ordered = OrderedRound(_correctOrder, random: _rnd);

    // ✅ نطق التعليمات
    _speak('رتّب: $_hint');

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
  //  ضغط على بطاقة
  // ═══════════════════════════════════════════════════════
  void _tapEmoji(String emoji) {
    if (_ordered.complete || _userOrder.contains(emoji)) return;

    HapticFeedback.lightImpact();
    setState(() => _ordered.selectValue(emoji));

    if (_userOrder.length == _correctOrder.length) {
      Future.delayed(const Duration(milliseconds: 400), _check);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  فحص الترتيب
  // ═══════════════════════════════════════════════════════
  void _check() {
    if (!mounted || !_ordered.complete) return;
    if (_ordered.correct) {
      // ✅ صحيح
      HapticFeedback.heavyImpact();
      setState(() {
        _score++;
        _streak++;
        _round++;
      });

      if (_streak >= 2) {
        _speak('ممتاز! متتالية رائعة');
      } else {
        _speak('أحسنت! ترتيب صحيح');
      }

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _newRound();
      });
    } else {
      // ❌ خطأ
      HapticFeedback.mediumImpact();
      _speak('حاول مرة أخرى — فكّر بالترتيب');

      setState(() {
        _ordered.reset();
        _streak = 0;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  //  عند الفوز
  // ═══════════════════════════════════════════════════════
  void _onWin() async {
    await GameProgressService.instance.record(((_score / _totalRounds) * 100).round());
    await VisualCelebration.show(
      context,
      message: 'أحسنت! $_score/$_totalRounds',
      emoji: '🧩',
      childName: widget.childName,
      duration: const Duration(seconds: 3),
    );
    if (mounted) Navigator.pop(context);
  }

  // ═══════════════════════════════════════════════════════
  //  واجهة المستخدم
  // ═══════════════════════════════════════════════════════
  void _updateGame(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) => _buildGame(context);
}
