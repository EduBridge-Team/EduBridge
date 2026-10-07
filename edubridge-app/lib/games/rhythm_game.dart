// لعبة الإيقاع — للتأتأة واضطرابات النطق
// الطفل ينقر مع الكلمات بإيقاع بطيء — يقلّل التأتأة ويساعد على الطلاقة
import 'dart:async';
import 'game_content.dart';
import '../features/games/domain/rhythm_session.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

part 'rhythm_game_view.dart';

class RhythmGame extends StatefulWidget {
  final String childName;

  const RhythmGame({super.key, required this.childName});

  @override
  State<RhythmGame> createState() => _RhythmGameState();
}

class _RhythmGameState extends State<RhythmGame> {
  // ═══════════════════════════════════════════════════════
  //  الكلمات — مجموعة بسيطة وسهلة النطق
  // ═══════════════════════════════════════════════════════
  static const _words = [
    'بيت',
    'شمس',
    'قمر',
    'نجم',
    'ماء',
    'خبز',
    'كتاب',
    'قلم',
    'باب',
    'نور',
    'زهر',
    'ورد',
  ];

  final _session = RhythmSession();
  List<String> get _sessionWords => _session.words;
  int get _currentIndex => _session.index;
  int get _tapCount => _session.tapCount;
  bool get _isPlaying => _session.playing;
  bool get _isPaused => _session.paused;
  Timer? _beatTimer;

  // ✅ سرعة الإيقاع (بالثواني) — بطيئة جداً
  final int _beatDurationSeconds = 3;

  // ✅ عدد الكلمات في كل جلسة
  final int _totalWords = 8;

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  @override
  void dispose() {
    _beatTimer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  //  بدء اللعبة
  // ═══════════════════════════════════════════════════════
  void _start() {
    setState(() {
      _session.start(GameContent.instance.take('rhythm', _words, _totalWords, (word) => word));
    });

    // رسالة ترحيب
    TtsService.instance.speakLineSlow(
      'هيا نتدرب على الإيقاع. انقر مع كل كلمة',
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) _speakCurrentWord();
    });
  }

  // ═══════════════════════════════════════════════════════
  //  نطق الكلمة الحالية + بدء المؤقّت
  // ═══════════════════════════════════════════════════════
  void _speakCurrentWord() {
    if (!_isPlaying || _isPaused || !mounted) return;

    if (_currentIndex >= _totalWords) {
      _finish();
      return;
    }

    // نطق الكلمة بصوت بطيء وواضح
    final word = _sessionWords[_currentIndex % _sessionWords.length];
    TtsService.instance.speakLineSlow(word);

    // بدء مؤقّت الانتقال للكلمة التالية
    _beatTimer?.cancel();
    _beatTimer = Timer(Duration(seconds: _beatDurationSeconds), () {
      if (!mounted || !_isPlaying || _isPaused) return;
      setState(() {
        _session.advance();
      });
      _speakCurrentWord();
    });
  }

  // ═══════════════════════════════════════════════════════
  //  ضغط زر "انقر"
  // ═══════════════════════════════════════════════════════
  void _tap() {
    if (!_isPlaying || _isPaused) return;
    HapticFeedback.lightImpact();
    setState(_session.tap);
  }

  // ═══════════════════════════════════════════════════════
  //  إيقاف / متابعة
  // ═══════════════════════════════════════════════════════
  void _pause() {
    setState(_session.pause);
    _beatTimer?.cancel();
    TtsService.instance.speakLineSlow('توقفنا مؤقتاً');
  }

  void _resume() {
    setState(_session.resume);
    _speakCurrentWord();
    TtsService.instance.speakLineSlow('نكمل');
  }

  // ═══════════════════════════════════════════════════════
  //  إعادة البدء
  // ═══════════════════════════════════════════════════════
  void _restart() {
    _beatTimer?.cancel();
    TtsService.instance.stop();
    _start();
  }

  // ═══════════════════════════════════════════════════════
  //  إنهاء اللعبة
  // ═══════════════════════════════════════════════════════
  void _finish() async {
    _beatTimer?.cancel();
    setState(_session.finish);

    TtsService.instance.speakLineSlow(
      'أحسنت يا ${widget.childName}! أتممت التمرين',
    );

    await GameProgressService.instance.record(100);

    VisualCelebration.show(
      context,
      message: 'أحسنت! أتممت التمرين',
      emoji: '🎵',
      childName: widget.childName,
      duration: const Duration(seconds: 3),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  // ═══════════════════════════════════════════════════════
  //  واجهة المستخدم
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6DD4),
        foregroundColor: Colors.white,
        title: const Text('🎵 لعبة الإيقاع'),
        actions: [
          if (_isPlaying) ...[
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              tooltip: _isPaused ? 'متابعة' : 'إيقاف مؤقت',
              onPressed: _isPaused ? _resume : _pause,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'إعادة',
              onPressed: _restart,
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isPlaying ? _buildPlaying(large) : _buildStart(large),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  شاشة البداية
  // ═══════════════════════════════════════════════════════
}
