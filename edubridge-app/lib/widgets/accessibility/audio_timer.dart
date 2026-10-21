import '../../l10n/l10n.dart';
// مؤقّت سمعي يحترم إعدادات الطفل ووقت الاستخدام الفعلي.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_feedback_policy.dart';
import '../../services/tts_service.dart';
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
    if (!_feedback.allowAutomaticSpeech) return;
    final p = AccessibilityService.instance.profile.value;
    unawaited(p.slowSpeech
      ? TtsService.instance.speakLineSlow(text, languageCode: context.l10n.localeName)
      : TtsService.instance.speakLine(text, languageCode: context.l10n.localeName));
  }

  void _profileChanged() {
    if (!_feedback.allowTaskDeadline && _isRunning) {
      _ticker?.cancel();
      _isRunning = false;
    }
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
    _lifecycle = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
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
    _announce(context.l10n.timerStartSpeech);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _lifecycle != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent == false || !_feedback.allowTaskDeadline) {
        return;
      }
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

  void _pause() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    _announce(context.l10n.timerPausedSpeech);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.total;
      _isRunning = false;
    });
    _announce(context.l10n.timerResetSpeech);
  }

  void _speakRemaining() {
    final mins = _remaining.inMinutes;
    if (mins > 0) {
      _announce(context.l10n.timerMinutesRemaining(mins));
    } else {
      _announce(
        context.l10n.timerSecondsRemaining(_remaining.inSeconds),
      );
    }
  }

  void _finish() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    _announce(
      context.l10n.timerFinishedSpeech(widget.childName),
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
      label: context.l10n.timerClockSemantics(context.l10n.adaptationMinutes(mins), context.l10n.adaptationSeconds(secs)),
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
                    context.l10n.timerAudioTitle,
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
              textDirection: TextDirection.ltr,
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
                    label: Text(_isRunning ? context.l10n.timerPause : context.l10n.timerStart),
                    onPressed: _remaining <= Duration.zero ? null : (_isRunning ? _pause : _start),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.timerReset),
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