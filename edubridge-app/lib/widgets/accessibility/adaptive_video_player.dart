// lib/widgets/adaptive/adaptive_video_player.dart
// مشغّل فيديو مع دعم الترجمات والوصف الصوتي
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../services/lesson_captions.dart';
import '../../theme.dart';
import '../../utils/adaptive_helper.dart';
part 'adaptive_video_player_view.dart';

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

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _created = false;
  String? _error;
  VideoPlayerController? _signController;
  bool _signFailed = false;
  bool _syncingSign = false;
  bool _lastPlaying = false;
  bool _foreground = true;
  bool _showCaptions = false;
  bool _showSignLanguage = false;
  List<LessonCaption> _captions = [];
  String _currentCaption = '';
  String _signLanguagePosition = 'bottom_right';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _created = true;
      await _controller.initialize();
      if (!mounted) return;
      await _controller.setLooping(false);

      // ✅ تحميل الترجمات إذا وُجدت
      if (widget.captionUrl != null) {
        await _loadCaptions(widget.captionUrl!);
      }

      if (!mounted) return;
      // ✅ تفعيل الترجمات تلقائياً للصمّ
      final profile = AccessibilityService.instance.profile.value;
      if (profile.videoCaptions) {
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
      if (widget.signLanguageUrl != null) _initializeSign();
      if (_foreground) await _controller.play();

      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذّر تشغيل الفيديو. حاول فتح الدرس مجدداً.');
    }
  }

  Future<void> _loadCaptions(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _captions = parseLessonCaptions(response.body);
      }
    } catch (_) {}
  }

  Future<void> _initializeSign() async {
    try {
      final sign = VideoPlayerController.networkUrl(Uri.parse(widget.signLanguageUrl!));
      _signController = sign;
      await sign.initialize();
      if (!mounted) return;
      await sign.setVolume(0);
      if (!mounted) return;
      setState(() {});
      await _syncSign();
    } catch (_) {
      if (mounted) setState(() => _signFailed = true);
    }
  }

  Future<void> _syncSign() async {
    final sign = _signController;
    if (_syncingSign || sign == null || !sign.value.isInitialized || !mounted) return;
    _syncingSign = true;
    try {
      final main = _controller.value;
      final target = main.position > sign.value.duration ? sign.value.duration : main.position;
      if ((sign.value.position - target).inMilliseconds.abs() > 350) {
        await sign.seekTo(target);
      }
      if (!mounted) return;
      if (sign.value.playbackSpeed != main.playbackSpeed) await sign.setPlaybackSpeed(main.playbackSpeed);
      if (!mounted) return;
      if (_foreground && _showSignLanguage && main.isPlaying && target < sign.value.duration) {
        if (!sign.value.isPlaying) await sign.play();
      } else if (sign.value.isPlaying) {
        await sign.pause();
      }
    } catch (_) {
      if (mounted) setState(() => _signFailed = true);
    } finally {
      _syncingSign = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && _created) {
      _controller.pause();
      _signController?.pause();
    }
  }

  void _onVideoUpdate() {
    if (!mounted || !_controller.value.isInitialized) return;
    final position = _controller.value.position;

    final caption = _captions.firstWhere(
      (c) => position >= c.start && position < c.end,
      orElse: () => const LessonCaption(
          start: Duration.zero, end: Duration.zero, text: ''),
    );

    if (caption.text != _currentCaption || _lastPlaying != _controller.value.isPlaying) {
      setState(() {
        _currentCaption = caption.text;
        _lastPlaying = _controller.value.isPlaying;
      });
    }
    _syncSign();
  }

  void _toggleCaptions() {
    AdaptiveHelper.hapticFeedback();
    setState(() => _showCaptions = !_showCaptions);
  }

  void _toggleSignLanguage() {
    AdaptiveHelper.hapticFeedback();
    setState(() => _showSignLanguage = !_showSignLanguage);
    _syncSign();
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
    WidgetsBinding.instance.removeObserver(this);
    if (_created) {
      _controller.removeListener(_onVideoUpdate);
      _controller.dispose();
    }
    _signController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildView(context);

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
            Center(child: _signFailed
                ? const Text('تعذّر تحميل لغة الإشارة', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white))
                : _signController?.value.isInitialized == true
                    ? AspectRatio(aspectRatio: _signController!.value.aspectRatio,
                        child: VideoPlayer(_signController!))
                    : const CircularProgressIndicator()),
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
                  _controller.seekTo(pos < const Duration(seconds: 10)
                      ? Duration.zero : pos - const Duration(seconds: 10));
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
                  _controller.seekTo(pos + const Duration(seconds: 10) > _controller.value.duration
                      ? _controller.value.duration : pos + const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
