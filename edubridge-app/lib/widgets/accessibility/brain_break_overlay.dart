// نافذة "فاصل ذهني" تظهر تلقائياً كل X دقيقة لطفل ADHD
// - تعمل تلقائياً حسب brainBreakIntervalMinutes
// - يمكن استدعاؤها يدوياً عبر BrainBreakDialog.show(context)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
import '../../utils/adaptive_feedback_policy.dart';

class BrainBreakScheduler extends StatefulWidget {
  final Widget child;
  final ValueListenable<AccessibilityProfile>? profileListenable;

  const BrainBreakScheduler({
    super.key,
    required this.child,
    this.profileListenable,
  });

  @override
  State<BrainBreakScheduler> createState() => _BrainBreakSchedulerState();
}

class _BrainBreakSchedulerState extends State<BrainBreakScheduler>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _showing = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    (widget.profileListenable ??
            AccessibilityService.instance.applicationProfile)
        .addListener(_reschedule);
    AccessibilityService.instance.activeChildId.addListener(_reschedule);
    _reschedule();
  }

  @override
  void didUpdateWidget(covariant BrainBreakScheduler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileListenable != widget.profileListenable) {
      (oldWidget.profileListenable ?? AccessibilityService.instance.applicationProfile)
          .removeListener(_reschedule);
      (widget.profileListenable ?? AccessibilityService.instance.applicationProfile)
          .addListener(_reschedule);
      _reschedule();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AccessibilityService.instance.activeChildId.removeListener(_reschedule);
    (widget.profileListenable ??
            AccessibilityService.instance.applicationProfile)
        .removeListener(_reschedule);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      _reschedule();
    } else {
      _timer?.cancel();
    }
  }

  void _reschedule() {
    _timer?.cancel();
    final p = (widget.profileListenable ??
            AccessibilityService.instance.applicationProfile)
        .value;
    if ((widget.profileListenable == null &&
        AccessibilityService.instance.activeChildId.value != null) ||
        !p.brainBreaksEnabled || _lifecycle != AppLifecycleState.resumed) {
      return;
    }
    _timer = Timer(
      Duration(minutes: p.brainBreakIntervalMinutes),
      _showBrainBreak,
    );
  }

  Future<void> _showBrainBreak() async {
    if (_showing || !mounted || (widget.profileListenable == null &&
        AccessibilityService.instance.activeChildId.value != null)) return;
    _showing = true;

    if (ModalRoute.of(context)?.isCurrent == false) {
      _showing = false;
      _reschedule();
      return;
    }
    await BrainBreakDialog.show(context, profile:
        (widget.profileListenable ?? AccessibilityService.instance.applicationProfile).value);

    _showing = false;
    if (mounted) _reschedule();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ═══════════════════════════════════════════════════════════
//  BrainBreakDialog — نافذة الفاصل الذهني (عامّة الآن)
// ═══════════════════════════════════════════════════════════
class BrainBreakDialog extends StatefulWidget {
  final AccessibilityProfile? profile;
  const BrainBreakDialog({super.key, this.profile});

  /// ✅ استدعاء مباشر من أي مكان
  static Future<void> show(BuildContext context, {AccessibilityProfile? profile}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrainBreakDialog(profile: profile),
    );
  }

  @override
  State<BrainBreakDialog> createState() => _BrainBreakDialogState();
}

class _BrainBreakDialogState extends State<BrainBreakDialog>
    with WidgetsBindingObserver {
  static const _moves = [
    ('🌿', 'استرح بالطريقة المريحة لك'),
    ('🤲', 'يمكنك طلب مساعدة شخص معك'),
    ('💧', 'يمكنك أخذ استراحة قصيرة بعيداً عن الشاشة'),
  ];

  late final AccessibilityProfile _profile;
  bool get _hideCountdown => !AdaptiveFeedbackPolicy(_profile).showCountdown;
  late int _secondsLeft;
  int get _baseDuration => _profile.brainBreakDurationSeconds.clamp(15, 120);
  int _extensions = 0;
  int get _duration => _baseDuration + 30 * _extensions;
  Timer? _t;
  int _moveIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profile = widget.profile ?? AccessibilityService.instance.profile.value;
    _secondsLeft = _baseDuration;
    _moveIndex = 0;

    // ✅ نطق الحركة بصوت هادئ
    _readSuggestion();

    _startTimer();
  }

  void _startTimer() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      if (_secondsLeft <= 1) {
        _finish();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _t?.cancel();
    }
  }

  void _extend() {
    if (_extensions >= 2) return;
    setState(() {
      _extensions++;
      _secondsLeft += 30;
    });
  }

  void _finish() {
    _t?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _t?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _shuffle() {
    setState(() {
      _moveIndex = (_moveIndex + 1) % _moves.length;
    });
    _readSuggestion();
  }

  void _readSuggestion() {
    if (!AdaptiveFeedbackPolicy(_profile).allowAutomaticSpeech) return;
    final text = 'وقت الراحة. ${_moves[_moveIndex].$2}';
    if (_profile.slowSpeech) {
      TtsService.instance.speakLineSlow(text);
    } else {
      TtsService.instance.speakLine(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final move = _moves[_moveIndex];
    final progress = 1 - (_secondsLeft / _duration);
    final still = _profile.sensoryCalmMode || _profile.reducedAnimations || _profile.noFlashing ||
        MediaQuery.disableAnimationsOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Text(
              'وقت الراحة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'استراحة قصيرة، ثم نكمل من نفس المكان. يمكنك الرجوع بزر جاهز.',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
            const SizedBox(height: 20),

            // الحركة (متحركة)
            if (still) Text(move.$1, style: const TextStyle(fontSize: 90))
            else TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Text(
                move.$1,
                style: const TextStyle(fontSize: 90),
              ),
            ),
            const SizedBox(height: 12),

            // وصف الحركة
            Text(
              move.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // شريط التقدّم
            if (!_hideCountdown) LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              color: AppColors.orange,
              backgroundColor: c.line,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),

            // العدّاد
            if (!_hideCountdown) Text(
              _secondsLeft <= 5 ? 'سنكمل بعد $_secondsLeft ثوانٍ' : 'باقي $_secondsLeft ثانية',
              style: TextStyle(
                fontSize: 15,
                color: c.muted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // الأزرار
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('اقتراح آخر'),
                    onPressed: _shuffle,
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56)),
                  icon: const Icon(Icons.more_time),
                  label: Text(_extensions >= 2 ? 'اكتملت التمديدات' : 'أحتاج وقتاً أكثر (+30 ثانية)'),
                  onPressed: _extensions >= 2 ? null : _extend,
                ),
                SizedBox(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('جاهز'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(48, 56),
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _finish,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}