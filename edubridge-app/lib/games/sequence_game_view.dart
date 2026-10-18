// Sequence-game presentation extracted from sequence_game.dart.
part of 'sequence_game.dart';

extension _SequenceGameView on _SequenceGameState {
  Widget _buildGame(BuildContext context) {
    final large = _profile.extraLargeTouchTargets;
    final motion = AdaptiveFeedbackPolicy(_profile,
      systemReduceMotion: MediaQuery.disableAnimationsOf(context)).allowMotion;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FA),
      appBar: BrandAppBar(
        title: const Text('🧩 لعبة الترتيب'),
        actions: [
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
                GameStatChip(
                  icon: '🎯',
                  label: 'الجولة',
                  value: '${_round + 1}/$_totalRounds',
                  color: const Color(0xFF1AA9B2),
                ),
                GameStatChip(
                  icon: '⭐',
                  label: 'النقاط',
                  value: '$_score',
                  color: const Color(0xFF57B25A),
                ),
                if (_streak >= 2)
                  GameStatChip(
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
          //  التعليمات
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF1AA9B2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.sort,
                    color: Color(0xFF1AA9B2),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: large ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F7D84),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط على الصور بالترتيب الصحيح',
                    style: TextStyle(
                      fontSize: large ? 15 : 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          //  صف الترتيب (3 خانات)
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1AA9B2),
                  width: 2,
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8, runSpacing: 8,
                children: List.generate(3, (i) {
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
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF1AA9B2)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: filled
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // خانة الإيموجي
                      AnimatedContainer(
                        duration: motion ? const Duration(milliseconds: 250) : Duration.zero,
                        width: large ? 80 : 68,
                        height: large ? 80 : 68,
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF1AA9B2)
                                  .withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: filled
                                ? const Color(0xFF1AA9B2)
                                : Colors.grey.shade300,
                            width: filled ? 2.5 : 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(fontSize: large ? 42 : 36),
                        ),
                      ),

                      // التسمية
                      const SizedBox(height: 4),
                      SizedBox(
                        width: large ? 85 : 75,
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
                    'اختر بالترتيب:',
                    style: TextStyle(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF12283A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: _shuffled.map((emoji) {
                      final used = _userOrder.contains(emoji);
                      final labelIndex = _correctOrder.indexOf(emoji);

                      return GestureDetector(
                        key: ValueKey('sequence_choice_$emoji'),
                        onTap: used ? null : () => _tapEmoji(emoji),
                        child: AnimatedOpacity(
                          duration: motion ? const Duration(milliseconds: 250) : Duration.zero,
                          opacity: used ? 0.25 : 1.0,
                          child: Container(
                            width: large ? 110 : 95,
                            constraints: BoxConstraints(minHeight: large ? 110 : 95),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: used
                                    ? Colors.grey.shade300
                                    : const Color(0xFF1AA9B2),
                                width: 2.5,
                              ),
                              boxShadow: used
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF1AA9B2)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 12,
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
                                      fontSize: large ? 52 : 44),
                                ),
                                if (!used)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2, left: 4, right: 4),
                                    child: Text(
                                      _correctLabels[labelIndex],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1AA9B2),
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
                    Semantics(liveRegion: true, child: Text(_feedback!, textAlign: TextAlign.center)),
                  GameRoundContinuation(key: ValueKey(_round),
                    answered: _answeredCorrectly, onContinue: _advance),
                  if (_userOrder.isNotEmpty && !_answeredCorrectly)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1AA9B2),
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

}
