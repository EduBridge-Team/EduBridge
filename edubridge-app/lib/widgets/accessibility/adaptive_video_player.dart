// lib/widgets/adaptive/adaptive_video_player.dart
// مشغّل فيديو مع دعم الترجمات والوصف الصوتي
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
import '../../utils/adaptive_helper.dart';

class AdaptiveVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? captionUrl;      // SRT/VTT file
  final String? audioDescription;
  final String? title;
  final String? signLanguageUrl;

  const AdaptiveVideoPlayer({
    super.key,
    required this.videoUrl,
    this.captionUrl,
    this.audioDescription,
    this.title,
    this.signLanguageUrl,
  });

  @override
  State<AdaptiveVideoPlayer> createState() => _AdaptiveVideoPlayerState();
}

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showCaptions = false;
  bool _showSignLanguage = false;
  List<_Caption> _captions = [];
  String _currentCaption = '';
  String _signLanguagePosition = 'bottom_right';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      await _controller.setLooping(false);

      // ✅ تحميل الترجمات إذا وُجدت
      if (widget.captionUrl != null) {
        await _loadCaptions(widget.captionUrl!);
      }

      // ✅ تفعيل الترجمات تلقائياً للصمّ
      final profile = AccessibilityService.instance.profile.value;
      if (profile.videoCaptions || profile.type == DisabilityType.deaf) {
        _showCaptions = true;
      }

      // ✅ تفعيل لغة الإشارة
      if (profile.signLanguageTranslation &&
          widget.signLanguageUrl != null) {
        _showSignLanguage = true;
      }

      // ✅ الوصف الصوتي للأعمى
      if (profile.audioDescriptions &&
          widget.audioDescription != null) {
        TtsService.instance.speakLine(widget.audioDescription!);
      }

      _controller.addListener(_onVideoUpdate);
      await _controller.play();

      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initialized = false);
    }
  }

  Future<void> _loadCaptions(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _captions = _parseVTT(response.body);
      }
    } catch (_) {}
  }

  List<_Caption> _parseVTT(String content) {
    final captions = <_Caption>[];
    final blocks = content.split('\n\n');
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      for (final line in lines) {
        if (line.contains('-->')) {
          final times = line.split('-->');
          if (times.length == 2) {
            final start = _parseTime(times[0].trim());
            final end = _parseTime(times[1].trim().split(' ')[0]);
            final textLines = lines.sublist(lines.indexOf(line) + 1);
            if (textLines.isNotEmpty) {
              captions.add(_Caption(
                start: start,
                end: end,
                text: textLines.join('\n'),
              ));
            }
          }
          break;
        }
      }
    }
    return captions;
  }

  Duration _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = double.tryParse(parts[2].replaceAll(',', '.')) ?? 0;
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds.toInt(),
        milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
      );
    }
    return Duration.zero;
  }

  void _onVideoUpdate() {
    if (!mounted || !_controller.value.isInitialized) return;
    final position = _controller.value.position;

    final caption = _captions.firstWhere(
      (c) => position >= c.start && position <= c.end,
      orElse: () => const _Caption(
          start: Duration.zero, end: Duration.zero, text: ''),
    );

    if (caption.text != _currentCaption) {
      setState(() => _currentCaption = caption.text);
    }
  }

  void _toggleCaptions() {
    AdaptiveHelper.hapticFeedback();
    setState(() => _showCaptions = !_showCaptions);
  }

  void _toggleSignLanguage() {
    AdaptiveHelper.hapticFeedback();
    setState(() => _showSignLanguage = !_showSignLanguage);
  }

  void _cycleSignPosition() {
    AdaptiveHelper.hapticFeedback();
    final positions = ['bottom_right', 'bottom_left', 'top_right', 'top_left'];
    final currentIndex = positions.indexOf(_signLanguagePosition);
    setState(() {
      _signLanguagePosition = positions[(currentIndex + 1) % positions.length];
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'فيديو', style: const TextStyle(fontSize: 16)),
        actions: [
          // ترجمات
          if (_captions.isNotEmpty)
            IconButton(
              icon: Icon(
                _showCaptions ? Icons.closed_caption : Icons.closed_caption_off,
                color: _showCaptions ? AppColors.orange : Colors.white,
              ),
              tooltip: 'الترجمات',
              onPressed: _toggleCaptions,
            ),
          // لغة إشارة
          if (widget.signLanguageUrl != null)
            IconButton(
              icon: Icon(
                _showSignLanguage
                    ? Icons.sign_language
                    : Icons.sign_language_outlined,
                color: _showSignLanguage ? AppColors.orange : Colors.white,
              ),
              tooltip: 'لغة الإشارة',
              onPressed: _toggleSignLanguage,
            ),
          // تغيير موضع لغة الإشارة
          if (_showSignLanguage)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              tooltip: 'نقل المترجم',
              onPressed: _cycleSignPosition,
            ),
        ],
      ),
      body: Stack(
        children: [
          // الفيديو
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // الترجمات
          if (_showCaptions && _currentCaption.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 120,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentCaption,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AdaptiveHelper.bodyFontSize + 2,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ),

          // لغة الإشارة
          if (_showSignLanguage && widget.signLanguageUrl != null)
            _buildSignLanguageOverlay(),

          // أدوات التحكم
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildSignLanguageOverlay() {
    const size = 140.0;
    double? top, bottom, left, right;

    switch (_signLanguagePosition) {
      case 'top_left':
        top = 20;
        left = 20;
        break;
      case 'top_right':
        top = 20;
        right = 20;
        break;
      case 'bottom_left':
        bottom = 100;
        left = 20;
        break;
      case 'bottom_right':
      default:
        bottom = 100;
        right = 20;
        break;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // فيديو لغة الإشارة (VideoPlayer آخر)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sign_language,
                      color: AppColors.orange, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'مترجم الإشارة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // زر إغلاق
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: _toggleSignLanguage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.orange,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  final pos = _controller.value.position;
                  _controller.seekTo(pos - const Duration(seconds: 10));
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 72,
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: AppColors.orange,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  final pos = _controller.value.position;
                  _controller.seekTo(pos + const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Caption {
  final Duration start;
  final Duration end;
  final String text;

  const _Caption({
    required this.start,
    required this.end,
    required this.text,
  });
}