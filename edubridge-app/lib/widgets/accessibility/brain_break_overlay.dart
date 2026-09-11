// نافذة "فاصل ذهني" تظهر تلقائياً كل X دقيقة لطفل ADHD
// - تعمل تلقائياً حسب brainBreakIntervalMinutes
// - يمكن استدعاؤها يدوياً عبر BrainBreakDialog.show(context)
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';

// ═══════════════════════════════════════════════════════════
//  BrainBreakScheduler — مجدول الفواصل الذهنية
// ═══════════════════════════════════════════════════════════
class BrainBreakScheduler extends StatefulWidget {
  final Widget child;
  const BrainBreakScheduler({super.key, required this.child});

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
    AccessibilityService.instance.profile.addListener(_reschedule);
    _reschedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AccessibilityService.instance.profile.removeListener(_reschedule);
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
    final p = AccessibilityService.instance.profile.value;
    if (!p.brainBreaksEnabled || _lifecycle != AppLifecycleState.resumed) {
      return;
    }
    _timer = Timer(
      Duration(minutes: p.brainBreakIntervalMinutes),
      _showBrainBreak,
    );
  }

  Future<void> _showBrainBreak() async {
    if (_showing || !mounted) return;
    _showing = true;

    await BrainBreakDialog.show(context);

    _showing = false;
    _reschedule();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ═══════════════════════════════════════════════════════════
//  BrainBreakDialog — نافذة الفاصل الذهني (عامّة الآن)
// ═══════════════════════════════════════════════════════════
class BrainBreakDialog extends StatefulWidget {
  const BrainBreakDialog({super.key});

  /// ✅ استدعاء مباشر من أي مكان
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BrainBreakDialog(),
    );
  }

  @override
  State<BrainBreakDialog> createState() => _BrainBreakDialogState();
}

class _BrainBreakDialogState extends State<BrainBreakDialog> {
  static const _moves = [
    ('🙆', 'قف ومدّد ذراعيك للأعلى'),
    ('🤸', 'قفزة صغيرة 5 مرات'),
    ('🤚', 'حرّك أصابعك بسرعة'),
    ('👀', 'انظر لشيء بعيد 10 ثوان'),
    ('🧘', 'خذ نفساً عميقاً 3 مرات'),
    ('🦘', 'اقفز في مكانك 10 قفزات'),
    ('💪', 'شدّ عضلات ذراعيك ثم أرخِها'),
    ('🌀', 'دُر حول نفسك مرتين'),
  ];

  int _secondsLeft = 30;
  Timer? _t;
  int _moveIndex = 0;

  @override
  void initState() {
    super.initState();
    _moveIndex = DateTime.now().millisecond % _moves.length;

    // ✅ نطق الحركة بصوت هادئ
    TtsService.instance.speakLine('وقت الراحة! ${_moves[_moveIndex].$2}');

    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _t?.cancel();
        Navigator.of(context).pop();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _shuffle() {
    setState(() {
      _moveIndex = (_moveIndex + 1) % _moves.length;
      _secondsLeft = 30;
    });
    TtsService.instance.speakLine(_moves[_moveIndex].$2);
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final move = _moves[_moveIndex];
    final progress = 1 - (_secondsLeft / 30);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Text(
              'وقت الراحة 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'استرخِ قليلاً لتعود أقوى',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
            const SizedBox(height: 20),

            // الحركة (متحركة)
            TweenAnimationBuilder<double>(
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
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              color: AppColors.orange,
              backgroundColor: c.line,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),

            // العدّاد
            Text(
              '$_secondsLeft ثانية',
              style: TextStyle(
                fontSize: 15,
                color: c.muted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // الأزرار
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shuffle),
                    label: const Text('حركة أخرى'),
                    onPressed: _shuffle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('جاهز'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}