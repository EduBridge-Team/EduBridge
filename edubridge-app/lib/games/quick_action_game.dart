// لعبة الحركة السريعة — للأطفال ذوي فرط الحركة (ADHD)
// الطفل ينفّذ حركات سريعة بسيطة مع نقر زر
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/encouragement_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

class QuickActionGame extends StatefulWidget {
  final String childName;

  const QuickActionGame({super.key, required this.childName});

  @override
  State<QuickActionGame> createState() => _QuickActionGameState();
}

class _QuickActionGameState extends State<QuickActionGame> {
  // ═══════════════════════════════════════════════════════
  //  الحركات — سجلات موضعية (emoji, label)
  // ═══════════════════════════════════════════════════════
  static const _actions = [
    ('👏', 'صفّق'),
    ('🦘', 'اقفز'),
    ('🤸', 'دُر حول نفسك'),
    ('🙌', 'ارفع يديك'),
    ('💪', 'شدّ عضلاتك'),
    ('👋', 'لوّح'),
    ('🤾', 'ارمِ'),
    ('🏃', 'اركض في مكانك'),
    ('🤚', 'حرّك أصابعك'),
    ('🧘', 'خذ نفساً عميقاً'),
    ('⏸️', 'توقّف ثانيتين'),
    ('🎯', 'المس رأسك'),
  ];

  late (String, String) _currentAction;
  int _score = 0;
  int _round = 0;
  int _streak = 0;

  // ═══════════════════════════════════════════════════════
  //  المؤقّت — حسب عمر الطفل وبروفايله
  // ═══════════════════════════════════════════════════════
  Timer? _ticker;
  int _secondsLeft = 30;
  bool _isPaused = false;
  bool _isFinished = false;

  // ═══════════════════════════════════════════════════════
  //  عدد الجولات
  // ═══════════════════════════════════════════════════════
  static const _totalSeconds = 60;

  final _rnd = Random();

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  @override
  void initState() {
    super.initState();
    _newAction();
    _startTimer();
    EncouragementService.instance.praiseStart();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  //  المؤقّت
  // ═══════════════════════════════════════════════════════
  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused || _isFinished) return;

      if (_secondsLeft <= 1) {
        _ticker?.cancel();
        _onFinish();
      } else {
        setState(() => _secondsLeft--);

        // تنبيه كل 10 ثوان
        if (_secondsLeft == 10) {
          TtsService.instance.speakLine('عشر ثوانٍ متبقية!');
        }
        if (_secondsLeft == 5) {
          TtsService.instance.speakLine('خمس ثوانٍ!');
        }
      }
    });
  }

  // ═══════════════════════════════════════════════════════
  //  حركة جديدة
  // ═══════════════════════════════════════════════════════
  void _newAction() {
    // اختيار حركة عشوائية مختلفة عن الحالية
    (String, String) next;
    do {
      next = _actions[_rnd.nextInt(_actions.length)];
    } while (next.$2 == _currentAction.$2 && _actions.length > 1);

    _currentAction = next;
    HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════════════════
  //  الضغط على "فعلتها"
  // ═══════════════════════════════════════════════════════
  void _tapDone() {
    if (_isPaused || _isFinished) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _score++;
      _round++;
      _streak++;
    });

    // تشجيع كل 5 حركات
    if (_round % 5 == 0) {
      EncouragementService.instance.praiseStreak();
    } else {
      // صوت قصير للتأكيد
      HapticFeedback.lightImpact();
    }

    _newAction();
  }

  // ═══════════════════════════════════════════════════════
  //  إيقاف / متابعة
  // ═══════════════════════════════════════════════════════
  void _pause() {
    setState(() => _isPaused = true);
    TtsService.instance.speakLine('توقفنا مؤقتاً');
  }

  void _resume() {
    setState(() => _isPaused = false);
    TtsService.instance.speakLine('نكمل');
  }

  // ═══════════════════════════════════════════════════════
  //  إنهاء اللعبة
  // ═══════════════════════════════════════════════════════
  void _onFinish() async {
    _isFinished = true;
    setState(() {});

    // رسالة تشجيع حسب النتيجة
    String message;
    String emoji;
    if (_score >= 20) {
      message = 'مذهل! $_score حركة في دقيقة!';
      emoji = '🏆';
    } else if (_score >= 15) {
      message = 'رائع! $_score حركة!';
      emoji = '🌟';
    } else if (_score >= 10) {
      message = 'أحسنت! $_score حركة';
      emoji = '⚡';
    } else {
      message = 'بداية جميلة! $_score حركة';
      emoji = '💪';
    }

    await VisualCelebration.show(
      context,
      message: message,
      emoji: emoji,
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
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2842B),
        foregroundColor: Colors.white,
        title: const Text('⚡ الحركة السريعة'),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: _isPaused ? 'متابعة' : 'إيقاف مؤقت',
            onPressed: _isFinished ? null : (_isPaused ? _resume : _pause),
          ),
        ],
      ),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════
          //  شريط المعلومات
          // ═══════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // المؤقّت الكبير
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: _secondsLeft <= 10
                          ? Colors.red
                          : const Color(0xFFF2842B),
                      size: large ? 32 : 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_secondsLeft',
                      style: TextStyle(
                        fontSize: large ? 44 : 38,
                        fontWeight: FontWeight.bold,
                        color: _secondsLeft <= 10
                            ? Colors.red
                            : const Color(0xFF12283A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ثانية',
                      style: TextStyle(
                        fontSize: large ? 18 : 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // شريط التقدّم
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _secondsLeft / _totalSeconds,
                    minHeight: 12,
                    backgroundColor:
                        const Color(0xFFF2842B).withValues(alpha: 0.15),
                    color: _secondsLeft <= 10
                        ? Colors.red
                        : const Color(0xFFF2842B),
                  ),
                ),

                const SizedBox(height: 12),

                // النقاط + المتتالية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip(
                      icon: '⭐',
                      label: 'النقاط',
                      value: '$_score',
                      color: const Color(0xFFF2842B),
                    ),
                    if (_streak >= 3)
                      _statChip(
                        icon: '🔥',
                        label: 'متتالية',
                        value: '$_streak',
                        color: const Color(0xFFE53935),
                      ),
                    _statChip(
                      icon: '🎯',
                      label: 'الحركات',
                      value: '$_round',
                      color: const Color(0xFF57B25A),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الحركة الحالية
          // ═══════════════════════════════════════════════
          Expanded(
            child: Center(
              child: _isFinished
                  ? _buildFinishedView(large)
                  : _buildPlayingView(large),
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  زر "فعلتها"
          // ═══════════════════════════════════════════════
          if (!_isFinished)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: large ? 110 : 90,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF57B25A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  icon: Icon(
                    Icons.check_circle,
                    size: large ? 52 : 44,
                  ),
                  label: Text(
                    'فعلتها!',
                    style: TextStyle(
                      fontSize: large ? 32 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isPaused ? null : _tapDone,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  عرض اللعب
  // ═══════════════════════════════════════════════════════
  Widget _buildPlayingView(bool large) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'افعل هذا:',
            style: TextStyle(
              fontSize: large ? 22 : 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // الإيموجي الكبير مع حركة نبض
          TweenAnimationBuilder<double>(
            key: ValueKey(_currentAction.$2),
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: large ? 220 : 190,
              height: large ? 220 : 190,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2842B), Color(0xFFFFC23C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF2842B).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _currentAction.$1,
                style: TextStyle(fontSize: large ? 130 : 110),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // اسم الحركة
          Text(
            _currentAction.$2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: large ? 36 : 30,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12283A),
            ),
          ),

          const SizedBox(height: 12),

          // رسالة تحفيزية
          Text(
            _isPaused
                ? '⏸️ متوقف مؤقتاً'
                : 'افعلها بسرعة ثم اضغط "فعلتها"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  عرض ما بعد الانتهاء
  // ═══════════════════════════════════════════════════════
  Widget _buildFinishedView(bool large) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 100)),
          const SizedBox(height: 20),
          Text(
            'أحسنت!',
            style: TextStyle(
              fontSize: large ? 42 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF57B25A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_score حركة في $_totalSeconds ثانية',
            style: TextStyle(
              fontSize: large ? 24 : 20,
              color: const Color(0xFF12283A),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  رقاقة إحصائيات
  // ═══════════════════════════════════════════════════════
  Widget _statChip({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
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
                  fontSize: 18,
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