part of 'quick_action_game.dart';

extension _QuickActionGameView on _QuickActionGameState {
  Widget _buildPlayingView(bool large) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'افعل هذا:',
            style: TextStyle(
              fontSize: large ? 22 : 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            key: ValueKey(_currentAction.$2),
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: large ? 220 : 190,
              height: large ? 220 : 190,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2842B), Color(0xFFFFC23C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF2842B).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _currentAction.$1,
                style: TextStyle(fontSize: large ? 130 : 110),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentAction.$2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: large ? 36 : 30,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12283A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isPaused
                ? '⏸️ متوقف مؤقتاً'
                : 'افعلها بسرعة ثم اضغط "فعلتها"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedView(bool large) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 100)),
          const SizedBox(height: 20),
          Text(
            'أحسنت!',
            style: TextStyle(
              fontSize: large ? 42 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF57B25A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_score حركة في $_QuickActionGameState._totalSeconds ثانية',
            style: TextStyle(
              fontSize: large ? 24 : 20,
              color: const Color(0xFF12283A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
