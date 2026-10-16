// Story sequencer presentation extracted from story_sequencer_game.dart.
part of 'story_sequencer_game.dart';

extension _StorySequencerGameView on _StorySequencerGameState {
  Widget _buildGame(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;
    final motion = AdaptiveFeedbackPolicy(_profile,
      systemReduceMotion: MediaQuery.disableAnimationsOf(context)).allowMotion;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FF),
      appBar: BrandAppBar(
        title: const Text('📖 رتّب القصة'),
        actions: [
          // زر إعادة الجولة
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'جولة جديدة',
            onPressed: _finishing || _answeredCorrectly ? null : _retry,
          ),
        ],
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
              spacing: 12, runSpacing: 8,
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
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
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
                        duration: motion ? const Duration(milliseconds: 250) : Duration.zero,
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
                          textScaler: TextScaler.noScaling,
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
          Padding(
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
                        key: ValueKey('story_choice_$emoji'),
                        onTap: used ? null : () => _tapEmoji(emoji),
                        child: AnimatedOpacity(
                          duration: motion ? const Duration(milliseconds: 250) : Duration.zero,
                          opacity: used ? 0.25 : 1.0,
                          child: Container(
                            width: large ? 100 : 90,
                            constraints: BoxConstraints(minHeight: large ? 100 : 90),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  emoji,
                                  textScaler: TextScaler.noScaling,
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
                  if (_feedback != null)
                    Semantics(liveRegion: true, child: Text(_feedback!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: large ? 20 : 18, fontWeight: FontWeight.bold))),
                  GameRoundContinuation(
                    key: ValueKey(_round), answered: _answeredCorrectly,
                    onContinue: _advance),
                  if (_userOrder.isNotEmpty && !_answeredCorrectly)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B6DD4),
                        minimumSize: const Size(200, 44),
                      ),
                      icon: const Icon(Icons.undo),
                      label: Text(
                        _feedback == null ? 'أعد الترتيب' : 'حاول مرة أخرى',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _finishing ? null : _retry,
                    ),

                  const SizedBox(height: 20),
                ],
              ),
          ),
        ],
      )),
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
