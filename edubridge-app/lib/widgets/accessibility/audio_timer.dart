// مؤقّت سمعي — يقرأ الوقت المتبقي كل دقيقة للأعمى
import 'dart:async';
import 'package:flutter/material.dart';
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

class _AudioTimerState extends State<AudioTimer> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.total;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    TtsService.instance.speakLine('سأخبرك بالوقت المتبقي كل دقيقة');
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          _finish();
        }
      });
      if (_remaining.inSeconds > 0 && _remaining.inSeconds % 60 == 0) {
        _speakRemaining();
      }
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    TtsService.instance.speakLine('تم الإيقاف مؤقتاً');
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.total;
      _isRunning = false;
    });
    TtsService.instance.speakLine('تم إعادة المؤقّت');
  }

  void _speakRemaining() {
    final mins = _remaining.inMinutes;
    if (mins > 0) {
      TtsService.instance.speakLine('تبقى $mins دقيقة');
    } else {
      TtsService.instance.speakLine(
        'تبقى ${_remaining.inSeconds} ثانية',
      );
    }
  }

  void _finish() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    TtsService.instance.speakLine(
      'انتهى الوقت يا ${widget.childName}! أحسنت',
    );
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: _isRunning ? _pause : _start,
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