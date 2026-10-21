import '../l10n/l10n.dart';
// لعبة مطابقة الأزواج
import 'dart:async';
import 'game_content.dart';
import '../features/games/domain/matching_board.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import '../services/accessibility_service.dart';
import '../services/encouragement_service.dart';
import '../theme.dart';
import '../widgets/accessibility/visual_celebration.dart';

class MatchingGame extends StatefulWidget {
  final String childName;
  final List<String>? items;

  const MatchingGame({
    super.key,
    required this.childName,
    this.items,
  });

  @override
  State<MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> with WidgetsBindingObserver {
  static const _defaultItems = [
    '🐶', '🐱', '🐼', '🦊', '🐸', '🦁', '🐧', '🐨',
    '🍎', '🍌', '🍓', '🍇', '🚗', '🚲', '✈️', '🚂',
    '⚽', '🏀', '🧸', '🎈', '🌻', '🌳', '🦋', '🐢',
  ];

  late MatchingBoard _board;
  int _generation = 0;
  List<MatchingCard> get _cards => _board.cards;
  int get _matches => _board.matches;
  int get _attempts => _board.attempts;
  int get _mistakes => _board.mistakes;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _resultRecorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_board.finished) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  void _startGame() {
    _resultRecorded = false;
    _generation++;
    final items = (widget.items ?? _defaultItems).toSet().toList();
    final selected = GameContent.instance.take('matching', items, 4, (item) => item);
    final all = [...selected, ...selected]..shuffle();

    _board = MatchingBoard(all);
    _secondsElapsed = 0;

    EncouragementService.instance.praiseGame();

    _startTimer();

    setState(() {});
  }

  void _flip(int index) {
    var ready = false;
    setState(() => ready = _board.flip(index));
    if (ready) _checkMatch();
  }

  void _checkMatch() async {
    final generation = _generation;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || generation != _generation) return;
    bool? matched;
    setState(() => matched = _board.resolve());
    if (matched == null) return;
    if (matched!) {
      if (_board.streak == 3) {
        EncouragementService.instance.praiseStreak();
      } else {
        EncouragementService.instance.praiseSuccess();
      }
      if (_board.finished) {
        _timer?.cancel();
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted || generation != _generation) return;
        _onWin();
      }
    } else if (_mistakes % 2 == 0) {
      EncouragementService.instance.gentleRetry();
    }
    setState(_board.release);
  }

  Future<void> _onWin() async {
    if (!mounted || _resultRecorded) return;
    _resultRecorded = true;
    final generation = _generation;
    final score = _board.scorePercent;
    await GameProgressService.instance.record(score);

    if (!mounted || generation != _generation) return;
    await VisualCelebration.show(
      context,
      message: context.l10n.matchingCompleted(score),
      emoji: '🏆',
      childName: widget.childName,
      duration: const Duration(seconds: 3),
    );

    if (mounted && generation == _generation) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            context.l10n.matchingWellDone,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statRow(context.l10n.matchingTime, context.l10n.matchingSeconds(_secondsElapsed)),
              _statRow(context.l10n.matchingAttempts, '$_attempts'),
              _statRow(context.l10n.matchingMistakes, '$_mistakes'),
              _statRow(context.l10n.matchingScore, '$score%'),
            ],
          )),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                icon: const Icon(Icons.replay),
                label: Text(context.l10n.matchingPlayAgain),
                onPressed: () {
                  Navigator.pop(context);
                  _startGame();
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final profile = AccessibilityService.instance.profile.value;
    final isCalm = profile.reducedAnimations;
    final cardFontSize = profile.extraLargeTouchTargets ? 72.0 : 60.0;

    return Scaffold(
      appBar: JisrAppBar(
        title: context.l10n.matchingTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.matchingNewGame,
            onPressed: _startGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: c.tintTeal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _infoChip('⏱️', context.l10n.matchingSecondsShort(_secondsElapsed))),
                Expanded(child: _infoChip('🎯', '$_matches/${_cards.length ~/ 2}')),
                Expanded(child: _infoChip('❌', '$_mistakes')),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, i) => _buildCard(
                  _cards[i],
                  i,
                  cardFontSize,
                  isCalm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Flexible(child: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        )),
      ],
    );
  }

  Widget _buildCard(
    MatchingCard card,
    int index,
    double fontSize,
    bool isCalm,
  ) {
    final c = JisrColors.of(context);
    final showFace = card.flipped || card.matched;

    return GestureDetector(
      onTap: () => _flip(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: isCalm ? 80 : 250),
        decoration: BoxDecoration(
          color: card.matched
              ? c.tintGreen
              : showFace
                  ? c.card
                  : AppColors.teal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: card.matched ? c.success : c.line,
            width: card.matched ? 3 : 2,
          ),
          boxShadow: isCalm
              ? null
              : [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: showFace
            ? Text(card.emoji, style: TextStyle(fontSize: fontSize))
            : const Icon(Icons.question_mark,
                size: 48, color: Colors.white),
      ),
    );
  }
}
