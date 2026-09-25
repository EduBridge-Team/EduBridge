// مشغّل فيديو ذكي — يتكيّف مع نوع الإعاقة
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
part 'video_lesson_player_view.dart';

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

      if (_profile.slowSpeech) {
        await _controller!.setPlaybackSpeed(0.75);
      }

      await _controller!.play();

      if (!mounted) return;
      setState(() => _initialized = true);

      if (_profile.type == DisabilityType.deaf ||
          _profile.visualAlertsEnabled) {
        setState(() => _showSubtitles = true);
      }

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
  Widget build(BuildContext context) => buildView(context);
}