// لعبة رتّب القصة — للأعمار 6-12
// الطفل يرى صوراً مبعثرة ويجب أن يرتّبها حسب ترتيب الأحداث
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

part 'story_sequencer_game_view.dart';

class StorySequencerGame extends StatefulWidget {
  final String childName;
  final int age;

  const StorySequencerGame({
    super.key,
    required this.childName,
    this.age = 8,
  });

  @override
  State<StorySequencerGame> createState() => _StorySequencerGameState();
}

class _StorySequencerGameState extends State<StorySequencerGame> {
  // كل قصة تحتوي على:
  // - emojis: الصور بالترتيب الصحيح
  // - labels: وصف كل صورة
  // - title: عنوان القصة
  static const _stories = [
    (
      title: 'رحلة الدجاجة',
      emojis: ['🥚', '🐣', '🐤', '🐔'],
      labels: ['البيضة', 'الكتكوت', 'الفرخ', 'الدجاجة'],
    ),
    (
      title: 'نموّ الشجرة',
      emojis: ['🌱', '🌿', '🌳', '🍎'],
      labels: ['البذرة', 'النبتة', 'الشجرة', 'الثمرة'],
    ),
    (
      title: 'يوم كامل',
      emojis: ['☀️', '🌤️', '🌧️', '🌙'],
      labels: ['الصباح', 'الظهر', 'المساء', 'الليل'],
    ),
    (
      title: 'دورة الماء',
      emojis: ['💧', '🌊', '☁️', '☔'],
      labels: ['التبخّر', 'البحر', 'السحاب', 'المطر'],
    ),
    (
      title: 'رحلة الفراشة',
      emojis: ['🐛', '🍃', '🦋', '🌸'],
      labels: ['اليسروع', 'الورقة', 'الفراشة', 'الزهرة'],
    ),
    (
      title: 'إعداد الطعام',
      emojis: ['🛒', '🥕', '🍳', '🍽️'],
      labels: ['التسوّق', 'الخضار', 'الطبخ', 'الأكل'],
    ),
    (
      title: 'رحلة في السيارة',
      emojis: ['🚗', '🛣️', '⛽', '🏠'],
      labels: ['البداية', 'الطريق', 'الوقود', 'الوصول'],
    ),
    (
      title: 'بناء المنزل',
      emojis: ['🧱', '🏗️', '🏠', '🏡'],
      labels: ['الطوب', 'البناء', 'المنزل', 'الحديقة'],
    ),
  ];

  late List<String> _correctOrder;
  late List<String> _correctLabels;
  late List<String> _shuffled;
  late String _title;
  List<String> _userOrder = [];

  int _round = 0;
  int _score = 0;
  int _streak = 0;
  final _rnd = Random();

  // ✅ عدد الجولات حسب العمر
  int get _totalRounds => widget.age <= 8 ? 4 : 6;

  // ✅ عدد البطاقات في كل قصة حسب العمر
  int get _cardCount {
    if (widget.age <= 7) return 3;
    return 4;
  }

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

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

    final story = _stories[_rnd.nextInt(_stories.length)];

    // خذ عدد البطاقات المناسب للعمر
    final count = _cardCount;
    _correctOrder = story.emojis.take(count).toList();
    _correctLabels = story.labels.take(count).toList();
    _title = story.title;

    // خلط البطاقات
    _shuffled = List<String>.from(_correctOrder);
    do {
      _shuffled.shuffle(_rnd);
    } while (_listEquals(_shuffled, _correctOrder));

    _userOrder = [];

    // نطق التعليمات
    _speak('رتّب قصة $_title. اضغط على الصور بالترتيب الصحيح');

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

    // هل اكتمل الترتيب؟
    if (_userOrder.length == _correctOrder.length) {
      Future.delayed(const Duration(milliseconds: 400), _check);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  فحص الترتيب
  // ═══════════════════════════════════════════════════════
  void _check() {
    if (_listEquals(_userOrder, _correctOrder)) {
      // ✅ ترتيب صحيح
      HapticFeedback.heavyImpact();
      setState(() {
        _score++;
        _streak++;
        _round++;
      });

      if (_streak >= 2) {
        _speak('ممتاز! ترتيب صحيح — متتالية رائعة');
      } else {
        _speak('ممتاز! ترتيب صحيح');
      }

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _newRound();
      });
    } else {
      // ❌ ترتيب خطأ
      HapticFeedback.mediumImpact();
      _speak('حاول مرة أخرى. فكّر بترتيب الأحداث');

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
      message: 'أحسنت! $_score/$_totalRounds قصص',
      emoji: '📖',
      childName: widget.childName,
      duration: const Duration(seconds: 3),
    );
    if (mounted) Navigator.pop(context);
  }

  // ═══════════════════════════════════════════════════════
  //  واجهة المستخدم
  // ═══════════════════════════════════════════════════════
  @override
  void _updateGame(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) => _buildGame(context);
}
