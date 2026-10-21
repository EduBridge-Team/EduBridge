part of 'rhythm_game.dart';

extension _RhythmGameView on _RhythmGameState {
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
            context.l10n.rhythmHeading,
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
              context.l10n.rhythmDescription,
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
                    Expanded(child: Text(
                      context.l10n.rhythmHowTo,
                      style: TextStyle(
                        fontSize: large ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B6DD4),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                _step('1', context.l10n.rhythmStepListen),
                _step('2', context.l10n.rhythmStepTap),
                _step('3', _profile.noTimedInteractions
                    ? context.l10n.rhythmStepContinue : context.l10n.rhythmStepTimed),
                _step('4', context.l10n.rhythmStepTotal(_totalWords)),
              ],
            ),
          ),

          const SizedBox(height: 40),

          if (_saveError) ...[
            Text(context.l10n.rhythmSaveFailed),
            TextButton(onPressed: _finish, child: Text(context.l10n.choiceSaveRetry)),
          ],
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
                context.l10n.rhythmStart,
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
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            )),
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
        ? RhythmWordDisplay.word(_sessionWords[_currentIndex % _sessionWords.length], context.l10n)
        : '🎉';

    final progress = _currentIndex / _totalWords;

    final motion = AdaptiveFeedbackPolicy(_profile,
      systemReduceMotion: MediaQuery.disableAnimationsOf(context)).allowMotion;
    return SingleChildScrollView(child: Column(
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12, runSpacing: 8,
                children: [
                  Text(
                    context.l10n.rhythmPosition(_currentIndex + 1, _totalWords),
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
        Center(
            child: AnimatedSwitcher(
              duration: motion ? const Duration(milliseconds: 400) : Duration.zero,
              child: Container(
                key: ValueKey(_currentIndex),
                width: large ? 300 : 260,
                constraints: BoxConstraints(minHeight: large ? 220 : 190),
                padding: const EdgeInsets.all(12),
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
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(
                  word, key: const ValueKey('rhythm_word'),
                  style: TextStyle(
                    fontSize: large ? 72 : 60,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B6DD4),
                  ),
                )),
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
              context.l10n.rhythmTap,
              style: TextStyle(
                fontSize: large ? 32 : 28,
                fontWeight: FontWeight.bold,
              ),
            )),
            onPressed: _isPaused ? null : _tap,
          ),
        ),

        TextButton.icon(onPressed: _isPaused ? null : () => _speakCurrentWord(explicit: true),
          icon: const Icon(Icons.volume_up_outlined), label: Text(context.l10n.wordBuilderListen)),
        GameRoundContinuation(
          key: ValueKey('rhythm_${_sessionGeneration}_$_currentIndex'),
          answered: _isPlaying && !_isPaused && !_finishing,
          delay: Duration(seconds: _beatDurationSeconds),
          onContinue: _advanceWord,
        ),
        const SizedBox(height: 12),

        // ═══════════════════════════════════════════════
        //  رسالة ودّية
        // ═══════════════════════════════════════════════
        Text(
          _isPaused
              ? context.l10n.rhythmPaused
              : _profile.noTimedInteractions
                  ? context.l10n.rhythmTakeTime
                  : context.l10n.rhythmPauseNotice,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ));
  }
}
