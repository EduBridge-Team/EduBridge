// Story sequencer presentation extracted from story_sequencer_game.dart.
part of 'story_sequencer_game.dart';

extension _StorySequencerGameView on _StorySequencerGameState {
  Widget _buildGame(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6DD4),
        foregroundColor: Colors.white,
        title: const Text('📖 رتّب القصة'),
        actions: [
          // زر إعادة الجولة
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'جولة جديدة',
            onPressed: () {
              _updateGame(() {
                _userOrder = [];
              });
              _speak('أعد ترتيب البطاقات');
            },
          ),
        ],
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
                  color: const Color(0xFF8B6DD4),
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

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════
          //  عنوان القصة + التعليمات
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: large ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF12283A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'رتّب الأحداث بالترتيب الصحيح',
                  style: TextStyle(
                    fontSize: large ? 16 : 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  صف الترتيب (الخانات الفارغة والمملوءة)
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B6DD4),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_correctOrder.length, (i) {
                  final filled = i < _userOrder.length;
                  final emoji = filled ? _userOrder[i] : '';
                  final label = filled
                      ? _correctLabels[_correctOrder.indexOf(_userOrder[i])]
                      : '';

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // رقم الترتيب
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF8B6DD4)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: filled ? Colors.white : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // خانة الإيموجي
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: large ? 68 : 58,
                        height: large ? 68 : 58,
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF8B6DD4).withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: filled
                                ? const Color(0xFF8B6DD4)
                                : Colors.grey.shade300,
                            width: filled ? 2 : 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: large ? 38 : 32),
                        ),
                      ),

                      // التسمية
                      const SizedBox(height: 4),
                      SizedBox(
                        width: large ? 70 : 60,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: filled
                                ? const Color(0xFF12283A)
                                : Colors.transparent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  البطاقات المتاحة
          // ═══════════════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'البطاقات المتاحة:',
                    style: TextStyle(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF12283A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: _shuffled.map((emoji) {
                      final used = _userOrder.contains(emoji);
                      final labelIndex =
                          _correctOrder.indexOf(emoji);

                      return GestureDetector(
                        onTap: used ? null : () => _tapEmoji(emoji),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: used ? 0.25 : 1.0,
                          child: Container(
                            width: large ? 100 : 90,
                            height: large ? 100 : 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: used
                                    ? Colors.grey.shade300
                                    : const Color(0xFF8B6DD4),
                                width: 2,
                              ),
                              boxShadow: used
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF8B6DD4)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  emoji,
                                  style: TextStyle(
                                      fontSize: large ? 48 : 42),
                                ),
                                if (!used &&
                                    _correctLabels.length > labelIndex)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2, left: 4, right: 4),
                                    child: Text(
                                      _correctLabels[labelIndex],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8B6DD4),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════
                  //  زر "أعد الترتيب"
                  // ═══════════════════════════════════════════════
                  if (_userOrder.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B6DD4),
                        minimumSize: const Size(200, 44),
                      ),
                      icon: const Icon(Icons.undo),
                      label: const Text(
                        'أعد الترتيب',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        _updateGame(() => _userOrder = []);
                        _speak('أعد المحاولة');
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  رقاقة معلومات صغيرة
  // ═══════════════════════════════════════════════════════
  Widget _infoChip({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
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
                  fontSize: 16,
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
