// لعبة الحركة السريعة — للأطفال ذوي فرط الحركة (ADHD)
// الطفل ينفّذ حركات سريعة بسيطة مع نقر زر
import 'dart:async';
import 'game_content.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../services/accessibility_service.dart';
import '../services/encouragement_service.dart';
import '../services/tts_service.dart';
import '../utils/adaptive_feedback_policy.dart';
import '../widgets/accessibility/visual_celebration.dart';

part 'quick_action_game_view.dart';

class QuickActionGame extends StatefulWidget {
  final String childName;

  const QuickActionGame({super.key, required this.childName});

  @override
  State<QuickActionGame> createState() => _QuickActionGameState();
}

class _QuickActionGameState extends State<QuickActionGame> {
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

  // ✅ إصلاح: قيمة ابتدائية بدل late — يمنع LateInitializationError
  (String, String) _currentAction = ('👏', 'صفّق');

  int _score = 0;
  int _round = 0;
  int _streak = 0;

  Timer? _ticker;
  int _secondsLeft = 30;
  bool _isPaused = false;
  bool _isFinished = false;
  bool _recorded = false;

  static const _totalSeconds = 30;


  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  bool get _timed => AdaptiveFeedbackPolicy(_profile).allowTaskDeadline;

  void _profileChanged() {
    if (mounted) setState(() {});
  }

  void _announce(String text) {
    if (AdaptiveHelper.shouldReadOnTap) AdaptiveHelper.speak(text);
  }

  Future<void> _stopSpeech() async {
    try { await TtsService.instance.stop(); } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.profile.addListener(_profileChanged);
    _startTimer();
    _newAction();
    EncouragementService.instance.praiseStart();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    AccessibilityService.instance.profile.removeListener(_profileChanged);
    unawaited(_stopSpeech());
    super.dispose();
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused || _isFinished || !_timed ||
          (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent == false) return;

      if (_secondsLeft <= 1) {
        _ticker?.cancel();
        _onFinish();
      } else {
        setState(() => _secondsLeft--);

        if (_secondsLeft == 10) {
          _announce('عشر ثوانٍ متبقية!');
        }
        if (_secondsLeft == 5) {
          _announce('خمس ثوانٍ!');
        }
      }
    });
  }

  void _newAction() {
    final next = GameContent.instance.pick('quick_action', _actions, (item) => item.$2);

    _currentAction = next;
    AdaptiveHelper.hapticFeedback();
  }

  void _tapDone() {
    if (_isPaused || _isFinished) return;

    setState(() {
      _score++;
      _round++;
      _streak++;
    });

    if (_round % 5 == 0) {
      EncouragementService.instance.praiseStreak();
    }

    _newAction();
  }

  void _pause() {
    setState(() => _isPaused = true);
    _announce('توقفنا مؤقتاً');
  }

  void _resume() {
    setState(() => _isPaused = false);
    _announce('نكمل');
  }

  Future<void> _onFinish() async {
    if (_isFinished) return;
    _ticker?.cancel();
    _isFinished = true;
    setState(() {});

    String message;
    String emoji;
    if (_score >= 20) {
      message = 'مذهل! $_score حركة!';
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

    try {
      if (!_recorded) {
        await GameProgressService.instance.record((_score * 5).clamp(0, 100).toInt());
        _recorded = true;
      }
      if (!mounted) return;
      await VisualCelebration.show(context, message: message, emoji: emoji,
        childName: widget.childName, duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFinished = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ النتيجة، حاول إنهاء اللعب مرة أخرى')));
    }
  }

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
      body: SingleChildScrollView(child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                if (_timed) ...[
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
                ],
                if (!_timed) const Text('بدون وقت — خذ راحتك'),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 8,
                  runSpacing: 8,
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
          Center(
              child: _isFinished
                  ? _buildFinishedView(large)
                  : _buildPlayingView(large),
          ),
          const SizedBox(height: 20),
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
          if (!_isFinished)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(width: double.infinity, child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(48, AdaptiveHelper.buttonHeight)),
                onPressed: _onFinish,
                child: const Text('إنهاء اللعب'),
              )),
            ),
        ],
      )),
    );
  }
}
