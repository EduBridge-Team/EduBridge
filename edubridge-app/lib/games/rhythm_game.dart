// لعبة الإيقاع — للتأتأة واضطرابات النطق
// الطفل ينقر مع الكلمات بإيقاع بطيء — يقلّل التأتأة ويساعد على الطلاقة
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

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

  int _currentIndex = 0;
  int _tapCount = 0;
  Timer? _beatTimer;
  bool _isPlaying = false;
  bool _isPaused = false;

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
      _isPlaying = true;
      _isPaused = false;
      _currentIndex = 0;
      _tapCount = 0;
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
    final word = _words[_currentIndex % _words.length];
    TtsService.instance.speakLineSlow(word);

    // بدء مؤقّت الانتقال للكلمة التالية
    _beatTimer?.cancel();
    _beatTimer = Timer(Duration(seconds: _beatDurationSeconds), () {
      if (!mounted || !_isPlaying || _isPaused) return;
      setState(() {
        _currentIndex++;
        _tapCount = 0;
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
    setState(() => _tapCount++);
  }

  // ═══════════════════════════════════════════════════════
  //  إيقاف / متابعة
  // ═══════════════════════════════════════════════════════
  void _pause() {
    setState(() => _isPaused = true);
    _beatTimer?.cancel();
    TtsService.instance.speakLineSlow('توقفنا مؤقتاً');
  }

  void _resume() {
    setState(() => _isPaused = false);
    _speakCurrentWord();
    TtsService.instance.speakLineSlow('نكمل');
  }

  // ═══════════════════════════════════════════════════════
  //  إعادة البدء
  // ═══════════════════════════════════════════════════════
  void _restart() {
    _beatTimer?.cancel();
    TtsService.instance.stop();
    setState(() {
      _currentIndex = 0;
      _tapCount = 0;
      _isPaused = false;
    });
    _start();
  }

  // ═══════════════════════════════════════════════════════
  //  إنهاء اللعبة
  // ═══════════════════════════════════════════════════════
  void _finish() {
    _beatTimer?.cancel();
    setState(() => _isPlaying = false);

    TtsService.instance.speakLineSlow(
      'أحسنت يا ${widget.childName}! أتممت التمرين',
    );

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
  Widget _buildStart(bool large) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // أيقونة كبيرة
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B6DD4), Color(0xFFB39DDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B6DD4).withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              '🎵',
              style: TextStyle(fontSize: 80),
            ),
          ),

          const SizedBox(height: 30),

          // العنوان
          Text(
            'لعبة الإيقاع',
            style: TextStyle(
              fontSize: large ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B6DD4),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // الوصف
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'انقر مع كل كلمة تسمعها\n'
              'الإيقاع يساعد على الطلاقة والتحدث بثقة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: large ? 18 : 16,
                color: Colors.grey.shade700,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // بطاقة "كيف تلعب"
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF8B6DD4).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF8B6DD4), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'كيف تلعب:',
                      style: TextStyle(
                        fontSize: large ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B6DD4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _step('1', 'ستسمع كلمة واحدة'),
                _step('2', 'انقر على الزر الكبير مرة واحدة'),
                _step('3', 'لا يوجد وقت محدّد — خذ راحتك'),
                _step('4', 'سنكمل معاً $_totalWords كلمات'),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // زر البدء
          SizedBox(
            width: double.infinity,
            height: large ? 90 : 70,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6DD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
              ),
              icon: Icon(Icons.play_arrow, size: large ? 40 : 32),
              label: Text(
                'ابدأ',
                style: TextStyle(
                  fontSize: large ? 26 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF8B6DD4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  شاشة اللعب
  // ═══════════════════════════════════════════════════════
  Widget _buildPlaying(bool large) {
    final word = _currentIndex < _totalWords
        ? _words[_currentIndex % _words.length]
        : '🎉';

    final progress = _currentIndex / _totalWords;

    return Column(
      children: [
        // ═══════════════════════════════════════════════
        //  شريط التقدم
        // ═══════════════════════════════════════════════
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الكلمة ${_currentIndex + 1} من $_totalWords',
                    style: TextStyle(
                      fontSize: large ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B6DD4),
                    ),
                  ),
                  if (_tapCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF57B25A)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '✓ $_tapCount',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF57B25A),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  backgroundColor: const Color(0xFF8B6DD4)
                      .withValues(alpha: 0.15),
                  color: const Color(0xFF8B6DD4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // ═══════════════════════════════════════════════
        //  الكلمة الحالية
        // ═══════════════════════════════════════════════
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_currentIndex),
                width: large ? 300 : 260,
                height: large ? 220 : 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF8B6DD4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B6DD4)
                          .withValues(alpha: 0.3),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: large ? 72 : 60,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B6DD4),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ═══════════════════════════════════════════════
        //  زر "انقر"
        // ═══════════════════════════════════════════════
        SizedBox(
          width: double.infinity,
          height: large ? 120 : 100,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B6DD4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 4,
            ),
            icon: Icon(
              Icons.touch_app,
              size: large ? 52 : 44,
            ),
            label: Text(
              'انقر',
              style: TextStyle(
                fontSize: large ? 32 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _isPaused ? null : _tap,
          ),
        ),

        const SizedBox(height: 12),

        // ═══════════════════════════════════════════════
        //  رسالة ودّية
        // ═══════════════════════════════════════════════
        Text(
          _isPaused
              ? '⏸️ متوقف مؤقتاً'
              : 'لا يوجد ضغط — خذ راحتك 💜',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}