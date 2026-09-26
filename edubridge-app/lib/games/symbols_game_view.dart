part of 'symbols_game.dart';

extension _SymbolsGameStateView on _SymbolsGameState {
  Widget buildView(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A6EA5),
        foregroundColor: Colors.white,
        title: const Text('🌈 لعبة الرموز'),
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
                  color: const Color(0xFF3A6EA5),
                ),
                _infoChip(
                  icon: '⭐',
                  label: 'النقاط',
                  value: '$_score',
                  color: const Color(0xFF57B25A),
                ),
                if (_streak >= 2)
                  _infoChip(
                    icon: '🔥',
                    label: 'متتالية',
                    value: '$_streak',
                    color: const Color(0xFFF2842B),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════
          //  تنبيه تعليمي
          // ═══════════════════════════════════════════════
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A6EA5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3A6EA5).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF3A6EA5),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الرموز تساعدك على التمييز بدون الاعتماد على اللون فقط',
                    style: TextStyle(
                      fontSize: large ? 14 : 12,
                      color: const Color(0xFF3A6EA5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الهدف المطلوب
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'أين هذا الرمز؟',
                  style: TextStyle(
                    fontSize: large ? 22 : 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // عرض الهدف بشكل كبير
                Container(
                  width: large ? 200 : 170,
                  height: large ? 200 : 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3A6EA5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3A6EA5)
                            .withValues(alpha: 0.25),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _target.$1,
                        style: TextStyle(
                          fontSize: large ? 100 : 85,
                          color: _target.$3,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _target.$2,
                        style: TextStyle(
                          fontSize: large ? 22 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF12283A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  الخيارات
          // ═══════════════════════════════════════════════
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: _options.map((option) {
                  return GestureDetector(
                    onTap: () => _check(option),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF3A6EA5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3A6EA5)
                                .withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // الرمز بلونه
                          Text(
                            option.$1,
                            style: TextStyle(
                              fontSize: large ? 68 : 56,
                              color: option.$3,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // الاسم
                          Text(
                            option.$2,
                            style: TextStyle(
                              fontSize: large ? 18 : 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF12283A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  
  }
}
