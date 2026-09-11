// لعبة التسلسل والترتيب — للتوحّد والإعاقة الذهنية
// الطفل يرى 3 صور مبعثرة ويجب أن يرتّبها حسب الترتيب الصحيح
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/accessibility/visual_celebration.dart';

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
  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1AA9B2),
        foregroundColor: Colors.white,
        title: const Text('🧩 لعبة الترتيب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'جولة جديدة',
            onPressed: () {
              setState(() => _userOrder = []);
              _speak('أعد ترتيب البطاقات');
            },
          ),
        ],
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
                  color: const Color(0xFF1AA9B2),
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

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════
          //  التعليمات
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF1AA9B2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.sort,
                    color: Color(0xFF1AA9B2),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: large ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F7D84),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط على الصور بالترتيب الصحيح',
                    style: TextStyle(
                      fontSize: large ? 15 : 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  صف الترتيب (3 خانات)
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1AA9B2),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) {
                  final filled = i < _userOrder.length;
                  final emoji = filled ? _userOrder[i] : '';
                  final label = filled
                      ? _correctLabels[_correctOrder.indexOf(_userOrder[i])]
                      : '';

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // رقم الترتيب
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF1AA9B2)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: filled
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // خانة الإيموجي
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: large ? 80 : 68,
                        height: large ? 80 : 68,
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF1AA9B2)
                                  .withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: filled
                                ? const Color(0xFF1AA9B2)
                                : Colors.grey.shade300,
                            width: filled ? 2.5 : 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: large ? 42 : 36),
                        ),
                      ),

                      // التسمية
                      const SizedBox(height: 4),
                      SizedBox(
                        width: large ? 85 : 75,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: filled
                                ? const Color(0xFF12283A)
                                : Colors.transparent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  البطاقات المتاحة
          // ═══════════════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'اختر بالترتيب:',
                    style: TextStyle(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF12283A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: _shuffled.map((emoji) {
                      final used = _userOrder.contains(emoji);
                      final labelIndex = _correctOrder.indexOf(emoji);

                      return GestureDetector(
                        onTap: used ? null : () => _tapEmoji(emoji),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: used ? 0.25 : 1.0,
                          child: Container(
                            width: large ? 110 : 95,
                            height: large ? 110 : 95,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: used
                                    ? Colors.grey.shade300
                                    : const Color(0xFF1AA9B2),
                                width: 2.5,
                              ),
                              boxShadow: used
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF1AA9B2)
                                            .withValues(alpha: 0.25),
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
                                  emoji,
                                  style: TextStyle(
                                      fontSize: large ? 52 : 44),
                                ),
                                if (!used)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2, left: 4, right: 4),
                                    child: Text(
                                      _correctLabels[labelIndex],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1AA9B2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════
                  //  زر "أعد الترتيب"
                  // ═══════════════════════════════════════════════
                  if (_userOrder.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1AA9B2),
                        minimumSize: const Size(200, 44),
                      ),
                      icon: const Icon(Icons.undo),
                      label: const Text(
                        'أعد الترتيب',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        setState(() => _userOrder = []);
                        _speak('أعد المحاولة');
                      },
                    ),

                  const SizedBox(height: 20),
                ],
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