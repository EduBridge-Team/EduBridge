part of 'visual_words_game.dart';

extension _VisualWordsGameStateView on _VisualWordsGameState {
  Widget buildView(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF1),
      appBar: BrandAppBar(
        title: Text(context.l10n.visualWordsTitle),
      ),
      body: SingleChildScrollView(child: Column(
        children: [
          // ═══════════════════════════════════════════════
          //  شريط المعلومات
          // ═══════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 12,
              runSpacing: 8,
              children: [
                GameStatChip(
                  icon: '🎯',
                  label: context.l10n.sequenceRound,
                  value: '$_roundNumber/$_totalRounds',
                  color: const Color(0xFF57B25A),
                ),
                GameStatChip(
                  icon: '⭐',
                  label: context.l10n.sequenceScore,
                  value: '$_score',
                  color: const Color(0xFFF2842B),
                ),
                if (_streak >= 2)
                  GameStatChip(
                    icon: '🔥',
                    label: context.l10n.sequenceStreak,
                    value: '$_streak',
                    color: const Color(0xFFE53935),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الصورة المطلوبة
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  context.l10n.visualWordsQuestion,
                  style: TextStyle(
                    fontSize: large ? 24 : 20,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // صورة كبيرة داخل دائرة
                Container(
                  width: large ? 220 : 190,
                  height: large ? 220 : 190,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF57B25A), Color(0xFF7BCF7E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF57B25A)
                            .withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _target.$1, key: const ValueKey('visual_target'),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(fontSize: large ? 130 : 115),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الخيارات (كلمات)
          // ═══════════════════════════════════════════════
          Padding(
              padding: const EdgeInsets.all(16),
              child: _optionCount == 3
                  ? _buildOptionsVertical(large)
                  : _buildOptionsGrid(large),
          ),
          SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GameRoundContinuation(
              key: ValueKey(_round),
              answered: _transitioning && !_resultRecorded,
              delay: const Duration(milliseconds: 900),
              onContinue: _advance,
            ),
          )),
        ],
      )),
    );
  
  }
}
