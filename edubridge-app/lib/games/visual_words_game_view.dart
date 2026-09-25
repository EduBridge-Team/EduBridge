part of 'visual_words_game.dart';

extension VisualWordsGameStateView on _VisualWordsGameState {
  Widget buildView(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF57B25A),
        foregroundColor: Colors.white,
        title: const Text('💙 الكلمات البصرية'),
      ),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════
          //  شريط المعلومات
          // ═══════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip(
                  icon: '🎯',
                  label: 'الجولة',
                  value: '${_round + 1}/$_totalRounds',
                  color: const Color(0xFF57B25A),
                ),
                _infoChip(
                  icon: '⭐',
                  label: 'النقاط',
                  value: '$_score',
                  color: const Color(0xFFF2842B),
                ),
                if (_streak >= 2)
                  _infoChip(
                    icon: '🔥',
                    label: 'متتالية',
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
                  'ما هذه الصورة؟',
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
                    _target.$1,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _optionCount == 3
                  ? _buildOptionsVertical(large)
                  : _buildOptionsGrid(large),
            ),
          ),
        ],
      ),
    );
  
  }
}
