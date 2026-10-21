import '../../l10n/l10n.dart';
import '../../utils/content_speech_language.dart';
// lib/widgets/adaptive/adaptive_video_player.dart
// مشغّل فيديو مع دعم الترجمات والوصف الصوتي
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../features/lessons/data/lesson_caption_repository.dart';
import '../../features/lessons/domain/lesson_media_policy.dart';
import '../../features/lessons/domain/caption_sound_cues.dart';
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
  final String? descriptionLanguageCode;

  const AdaptiveVideoPlayer({
    super.key,
    required this.videoUrl,
    this.captionUrl,
    this.audioDescription,
    this.title,
    this.signLanguageUrl,
    this.descriptionLanguageCode,
  });

  @override
  State<AdaptiveVideoPlayer> createState() => _AdaptiveVideoPlayerState();
}

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _created = false;
  bool _error = false;
  VideoPlayerController? _signController;
  bool _signFailed = false;
  bool _syncingSign = false;
  bool _lastPlaying = false;
  bool _foreground = true;
  bool _showCaptions = false;
  bool _showSignLanguage = false;
  final _captionRepository = LessonCaptionRepository();
  List<LessonCaption> _captions = [];
  String _currentCaption = '';
  String _signLanguagePosition = 'bottom_right';
  late AccessibilityProfile _lastProfile;

  @override
  void initState() {
    super.initState();
    _lastProfile = AccessibilityService.instance.profile.value;
    WidgetsBinding.instance.addObserver(this);
    AccessibilityService.instance.profile.addListener(_refreshProfile);
    _initialize();
  }

  void _refreshProfile() {
    if (!mounted) return;
    final next = AccessibilityService.instance.profile.value;
    setState(() {
      if (next.videoCaptions != _lastProfile.videoCaptions) {
        _showCaptions = next.videoCaptions;
      }
      if (next.signLanguageTranslation != _lastProfile.signLanguageTranslation) {
        _showSignLanguage = next.signLanguageTranslation;
      }
      _lastProfile = next;
    });
    if (_initialized) _syncSign();
  }

  String get _displayCaption => _showCaptions ? _currentCaption
      : AccessibilityService.instance.profile.value.soundDescriptions
          ? captionSoundCues(_currentCaption) : '';

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
          !profile.sensoryCalmMode &&
          widget.audioDescription != null) {
        _readDescription();
      }

      _controller.addListener(_onVideoUpdate);
      if (widget.signLanguageUrl != null) _initializeSign();
      if (_foreground) await _controller.play();

      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _readDescription() {
    final text = widget.audioDescription?.trim();
    if (text == null || text.isEmpty) return;
    if (AccessibilityService.instance.profile.value.slowSpeech) {
      TtsService.instance.speakLineSlow(text, languageCode: ContentSpeechLanguage.resolve(text, override: widget.descriptionLanguageCode));
    } else {
      TtsService.instance.speakLine(text, languageCode: ContentSpeechLanguage.resolve(text, override: widget.descriptionLanguageCode));
    }
  }

  Future<void> _loadCaptions(String url) async {
    final captions = await _captionRepository.load(url);
    if (!mounted) return;
    _captions = captions;
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
      final target = LessonMediaPolicy.signTarget(main.position, sign.value.duration);
      if (LessonMediaPolicy.needsSignSeek(sign.value.position, target)) {
        await sign.seekTo(target);
      }
      if (!mounted) return;
      if (sign.value.playbackSpeed != main.playbackSpeed) await sign.setPlaybackSpeed(main.playbackSpeed);
      if (!mounted) return;
      if (LessonMediaPolicy.shouldPlaySign(
          foreground: _foreground, visible: _showSignLanguage,
          mainPlaying: main.isPlaying, target: target, duration: sign.value.duration)) {
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

    final caption = LessonMediaPolicy.captionAt(_captions, position);

    if (caption != _currentCaption || _lastPlaying != _controller.value.isPlaying) {
      setState(() {
        _currentCaption = caption;
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
    setState(() {
      _signLanguagePosition = LessonMediaPolicy.nextSignPosition(_signLanguagePosition);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AccessibilityService.instance.profile.removeListener(_refreshProfile);
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
                ? Text(context.l10n.lessonVideoSignFailed, textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white))
                : _signController?.value.isInitialized == true
                    ? AspectRatio(aspectRatio: _signController!.value.aspectRatio,
                        child: VideoPlayer(_signController!))
                    : const CircularProgressIndicator()),
            // زر إغلاق
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: context.l10n.lessonVideoCloseSigns,
                onPressed: _toggleSignLanguage,
                style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.7)),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
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
                tooltip: context.l10n.lessonVideoRewind,
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
                tooltip: _controller.value.isPlaying ? context.l10n.lessonVideoPause : context.l10n.lessonVideoPlay,
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
                tooltip: context.l10n.lessonVideoForward,
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
