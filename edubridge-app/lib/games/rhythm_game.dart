// لعبة الإيقاع — للتأتأة واضطرابات النطق
// تدريب على الاستماع والنقر مع كلمات بسيطة
import 'game_content.dart';
import '../features/games/domain/rhythm_session.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../utils/adaptive_feedback_policy.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';
import '../widgets/accessibility/game_round_continuation.dart';

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
  int _sessionGeneration = 0;
  bool _finishing = false;
  bool _recorded = false;
  bool _saveError = false;

  // ✅ سرعة الإيقاع (بالثواني) — بطيئة جداً
  final int _beatDurationSeconds = 3;

  // ✅ عدد الكلمات في كل جلسة
  final int _totalWords = 8;

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.profile.addListener(_profileChanged);
  }

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
  void dispose() {
    AccessibilityService.instance.profile.removeListener(_profileChanged);
    _stopSpeech();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  //  بدء اللعبة
  // ═══════════════════════════════════════════════════════
  void _start() {
    if (_finishing) return;
    setState(() {
      _sessionGeneration++;
      _recorded = false;
      _saveError = false;
      _session.start(GameContent.instance.take('rhythm', _words, _totalWords, (word) => word));
    });
    _speakCurrentWord();
  }

  // ═══════════════════════════════════════════════════════
  //  نطق الكلمة الحالية + بدء المؤقّت
  // ═══════════════════════════════════════════════════════
  void _speakCurrentWord({bool explicit = false}) {
    if (!_isPlaying || _isPaused || _finishing || !mounted || _session.complete) return;
    final word = _session.currentWord;
    if (explicit) {
      AdaptiveHelper.speak(word);
    } else {
      _announce(word);
    }
  }

  Future<void> _advanceWord() async {
    if (!_isPlaying || _isPaused || _finishing) return;
    setState(_session.advance);
    if (_session.complete) {
      await _finish();
    } else {
      _speakCurrentWord();
    }
  }

  // ═══════════════════════════════════════════════════════
  //  ضغط زر "انقر"
  // ═══════════════════════════════════════════════════════
  void _tap() {
    if (!_isPlaying || _isPaused || _finishing) return;
    AdaptiveHelper.hapticFeedback();
    setState(_session.tap);
  }

  // ═══════════════════════════════════════════════════════
  //  إيقاف / متابعة
  // ═══════════════════════════════════════════════════════
  void _pause() {
    setState(_session.pause);
    _announce('توقفنا مؤقتاً');
  }

  void _resume() {
    setState(_session.resume);
    _speakCurrentWord();
  }

  // ═══════════════════════════════════════════════════════
  //  إعادة البدء
  // ═══════════════════════════════════════════════════════
  Future<void> _restart() async {
    await _stopSpeech();
    if (mounted && !_finishing) _start();
  }

  // ═══════════════════════════════════════════════════════
  //  إنهاء اللعبة
  // ═══════════════════════════════════════════════════════
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() { _finishing = true; _session.finish(); _saveError = false; });
    try {
      if (!_recorded) {
        await GameProgressService.instance.record(100);
        _recorded = true;
      }
      if (!mounted) return;
      await VisualCelebration.show(context, message: 'أحسنت! أتممت التمرين',
        emoji: '🎵', childName: widget.childName, duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() { _finishing = false; _saveError = true; });
    }
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
              onPressed: _finishing ? null : (_isPaused ? _resume : _pause),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'إعادة',
              onPressed: _finishing ? null : _restart,
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _finishing
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(), Text('جارٍ حفظ النتيجة')]))
            : _isPlaying ? _buildPlaying(large) : _buildStart(large),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  شاشة البداية
  // ═══════════════════════════════════════════════════════
}
