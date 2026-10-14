// مؤقّت سمعي يحترم إعدادات الطفل ووقت الاستخدام الفعلي.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_feedback_policy.dart';
import '../../utils/adaptive_helper.dart';
import '../../theme.dart';

class AudioTimer extends StatefulWidget {
  final Duration total;
  final String childName;
  final VoidCallback? onFinished;

  const AudioTimer({
    super.key,
    required this.total,
    required this.childName,
    this.onFinished,
  });

  @override
  State<AudioTimer> createState() => _AudioTimerState();
}

class _AudioTimerState extends State<AudioTimer> with WidgetsBindingObserver {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _isRunning = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  AdaptiveFeedbackPolicy get _feedback =>
      AdaptiveFeedbackPolicy(AccessibilityService.instance.profile.value);

  void _announce(String text) {
    if (_feedback.allowAutomaticSpeech) AdaptiveHelper.speak(text);
  }

  void _profileChanged() {
    if (!_feedback.allowTaskDeadline && _isRunning) _pause(announce: false);
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
  }

  @override
  void initState() {
    super.initState();
    _remaining = widget.total;
    WidgetsBinding.instance.addObserver(this);
    AccessibilityService.instance.profile.addListener(_profileChanged);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AccessibilityService.instance.profile.removeListener(_profileChanged);
    super.dispose();
  }

  void _start() {
    if (_isRunning || _remaining <= Duration.zero || !_feedback.allowTaskDeadline) return;
    setState(() => _isRunning = true);
    _announce('سأخبرك بالوقت المتبقي كل دقيقة');
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _lifecycle != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent == false || !_feedback.allowTaskDeadline) return;
      if (_remaining <= const Duration(seconds: 1)) {
        setState(() => _remaining = Duration.zero);
        _finish();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
      if (_remaining.inSeconds > 0 && _remaining.inSeconds % 60 == 0) {
        _speakRemaining();
      }
    });
  }

  void _pause({bool announce = true}) {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    if (announce) _announce('تم الإيقاف مؤقتاً');
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.total;
      _isRunning = false;
    });
    _announce('تم إعادة المؤقّت');
  }

  void _speakRemaining() {
    final mins = _remaining.inMinutes;
    if (mins > 0) {
      _announce('تبقى $mins دقيقة');
    } else {
      _announce(
        'تبقى ${_remaining.inSeconds} ثانية',
      );
    }
  }

  void _finish() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    _announce(
      'انتهى الوقت يا ${widget.childName}! أحسنت',
    );
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_feedback.allowTaskDeadline) return const SizedBox.shrink();
    final c = JisrColors.of(context);
    final mins = _remaining.inMinutes;
    final secs = _remaining.inSeconds % 60;

    return Semantics(
      label: 'المؤقّت: $mins دقيقة و $secs ثانية',
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: c.tintTeal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.volume_up,
                    size: 36, color: AppColors.tealDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'المؤقّت السمعي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$mins:${secs.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'إيقاف' : 'ابدأ'),
                    onPressed: _remaining <= Duration.zero ? null : (_isRunning ? _pause : _start),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة'),
                    onPressed: _reset,
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