part of 'adaptive_video_player.dart';

extension _AdaptiveVideoPlayerStateView on _AdaptiveVideoPlayerState {
  Widget buildView(BuildContext context) {
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
}
