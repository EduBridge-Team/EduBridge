part of 'video_lesson_player.dart';

extension _VideoLessonPlayerStateView on _VideoLessonPlayerState {
  Widget buildView(BuildContext context) {
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
