// لعبة التسلسل والترتيب — للتوحّد والإعاقة الذهنية
// الطفل يرى 3 صور مبعثرة ويجب أن يرتّبها حسب الترتيب الصحيح
import 'dart:math';
import 'package:flutter/material.dart';
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
      emojis: ['🐣', '🐥', '🐔'],
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

  late List<String> _shuffled;
  late List<String> _correctOrder;
  late List<String> _correctLabels;
  late String _hint;
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  List<String> _userOrder = [];
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

    final seq = _sequences[_rnd.nextInt(_sequences.length)];
    _correctOrder = List<String>.from(seq.emojis);
    _correctLabels = List<String>.from(seq.labels);
    _hint = seq.title;

    // خلط الترتيب (مع ضمان ترتيب مختلف)
    do {
      _shuffled = List<String>.from(_correctOrder);
      _shuffled.shuffle(_rnd);
    } while (_listEquals(_shuffled, _correctOrder));

    _userOrder = [];

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

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════
  //  ضغط على بطاقة
  // ═══════════════════════════════════════════════════════
  void _tapEmoji(String emoji) {
    if (_userOrder.contains(emoji)) return;

    HapticFeedback.lightImpact();
    setState(() => _userOrder.add(emoji));

    if (_userOrder.length == _correctOrder.length) {
      Future.delayed(const Duration(milliseconds: 400), _check);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  فحص الترتيب
  // ═══════════════════════════════════════════════════════
  void _check() {
    if (_listEquals(_userOrder, _correctOrder)) {
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
        _userOrder = [];
        _streak = 0;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  //  عند الفوز
  // ═══════════════════════════════════════════════════════
  void _onWin() async {
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
