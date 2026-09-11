// مشغّل فيديو ذكي — يتكيّف مع نوع الإعاقة
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';

class VideoLessonPlayer extends StatefulWidget {
  final String videoUrl;
  final String? localPath;
  final String lessonTitle;
  final String? subtitles;
  final String? audioDescription;

  const VideoLessonPlayer({
    super.key,
    required this.videoUrl,
    required this.lessonTitle,
    this.localPath,
    this.subtitles,
    this.audioDescription,
  });

  @override
  State<VideoLessonPlayer> createState() => _VideoLessonPlayerState();
}

class _VideoLessonPlayerState extends State<VideoLessonPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _showSubtitles = false;
  bool _audioDescriptionOn = false;
  String? _error;

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final source = widget.localPath != null
          ? VideoPlayerController.file(File(widget.localPath!))
          : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      _controller = source;
      await _controller!.initialize();

      // بطء السرعة للإعاقة الذهنية
      if (_profile.slowSpeech) {
        await _controller!.setPlaybackSpeed(0.75);
      }

      await _controller!.play();

      if (!mounted) return;
      setState(() => _initialized = true);

      // للأصمّ: فعّل الترجمات تلقائياً
      if (_profile.type == DisabilityType.deaf ||
          _profile.visualAlertsEnabled) {
        setState(() => _showSubtitles = true);
      }

      // للأعمى: وصف صوتي تلقائي
      if (_profile.type == DisabilityType.blind) {
        _startAudioDescription();
      }

      _controller!.addListener(_onVideoProgress);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialized = false;
          _error = 'تعذّر تحميل الفيديو';
        });
      }
    }
  }

  void _onVideoProgress() {
    if (_controller == null || !mounted) return;

    // التكرار التلقائي للإعاقة الذهنية
    if (_controller!.value.position >= _controller!.value.duration &&
        _profile.type == DisabilityType.mildIntellectual) {
      _controller!.seekTo(Duration.zero);
      _controller!.play();
      TtsService.instance.speakLine('سنعيد الفيديو مرة أخرى');
    }
  }

  void _startAudioDescription() {
    if (widget.audioDescription != null) {
      TtsService.instance.speakLineSlow(
        'فيديو الدرس: ${widget.lessonTitle}. '
        '${widget.audioDescription}',
      );
      setState(() => _audioDescriptionOn = true);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // ترجمات
          IconButton(
            icon: Icon(
              _showSubtitles ? Icons.closed_caption : Icons.closed_caption_off,
              color: _showSubtitles ? AppColors.orange : Colors.white,
            ),
            tooltip: 'الترجمات',
            onPressed: () {
              setState(() => _showSubtitles = !_showSubtitles);
            },
          ),
          // وصف صوتي
          if (_profile.type == DisabilityType.blind)
            IconButton(
              icon: Icon(
                _audioDescriptionOn ? Icons.volume_up : Icons.volume_off,
                color: _audioDescriptionOn ? AppColors.orange : Colors.white,
              ),
              tooltip: 'الوصف الصوتي',
              onPressed: () {
                if (_audioDescriptionOn) {
                  TtsService.instance.stop();
                } else {
                  _startAudioDescription();
                }
                setState(() => _audioDescriptionOn = !_audioDescriptionOn);
              },
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // ─── الفيديو ───
                Expanded(
                  child: Center(
                    child: _initialized && _controller != null
                        ? AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: Stack(
                              children: [
                                VideoPlayer(_controller!),
                                // الترجمات
                                if (_showSubtitles && widget.subtitles != null)
                                  Positioned(
                                    bottom: 20,
                                    left: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.subtitles!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                  ),
                ),

                // ─── أزرار التحكّم ───
                if (_initialized && _controller != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black87,
                    child: Column(
                      children: [
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing:
                              _profile.type != DisabilityType.mildIntellectual,
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
                              icon: const Icon(Icons.replay_10,
                                  color: Colors.white, size: 36),
                              onPressed: () {
                                final pos = _controller!.value.position;
                                _controller!.seekTo(
                                  pos - const Duration(seconds: 10),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _controller!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: AppColors.orange,
                                size: 72,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_controller!.value.isPlaying) {
                                    _controller!.pause();
                                  } else {
                                    _controller!.play();
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10,
                                  color: Colors.white, size: 36),
                              onPressed: () {
                                final pos = _controller!.value.position;
                                _controller!.seekTo(
                                  pos + const Duration(seconds: 10),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}