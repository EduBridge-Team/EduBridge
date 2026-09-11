// لعبة مطابقة الأزواج
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

class _MatchingGameState extends State<MatchingGame> {
  static const _defaultItems = [
    '🐶', '🐱', '🐼', '🦊', '🐸', '🦁', '🐧', '🐨',
  ];

  late List<_Card> _cards;
  int? _firstIndex;
  int? _secondIndex;
  bool _locked = false;
  int _matches = 0;
  int _attempts = 0;
  int _mistakes = 0;
  int _streak = 0;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    final items = widget.items ?? _defaultItems;
    final selected = (List<String>.from(items)..shuffle()).take(4).toList();
    final all = [...selected, ...selected]..shuffle();

    _cards = all
        .map((emoji) => _Card(emoji: emoji, matched: false, flipped: false))
        .toList();

    _firstIndex = null;
    _secondIndex = null;
    _matches = 0;
    _attempts = 0;
    _mistakes = 0;
    _streak = 0;
    _secondsElapsed = 0;
    _locked = false;

    EncouragementService.instance.praiseGame();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    setState(() {});
  }

  void _flip(int index) {
    if (_locked || _cards[index].flipped || _cards[index].matched) return;

    setState(() {
      _cards[index] = _cards[index].copyWith(flipped: true);
    });

    if (_firstIndex == null) {
      _firstIndex = index;
    } else if (_secondIndex == null) {
      _secondIndex = index;
      _attempts++;
      _checkMatch();
    }
  }

  void _checkMatch() async {
    _locked = true;
    await Future.delayed(const Duration(milliseconds: 700));

    final first = _cards[_firstIndex!];
    final second = _cards[_secondIndex!];

    if (first.emoji == second.emoji) {
      setState(() {
        _cards[_firstIndex!] = first.copyWith(matched: true);
        _cards[_secondIndex!] = second.copyWith(matched: true);
        _matches++;
        _streak++;
      });

      if (_streak == 3) {
        EncouragementService.instance.praiseStreak();
      } else {
        EncouragementService.instance.praiseSuccess();
      }

      if (_matches == 4) {
        _timer?.cancel();
        await Future.delayed(const Duration(milliseconds: 400));
        _onWin();
      }
    } else {
      setState(() {
        _cards[_firstIndex!] = first.copyWith(flipped: false);
        _cards[_secondIndex!] = second.copyWith(flipped: false);
        _mistakes++;
        _streak = 0;
      });

      if (_mistakes % 2 == 0) {
        EncouragementService.instance.gentleRetry();
      }
    }

    setState(() {
      _firstIndex = null;
      _secondIndex = null;
      _locked = false;
    });
  }

  Future<void> _onWin() async {
    final score = ((4 / _attempts) * 100).round().clamp(0, 100);

    await VisualCelebration.show(
      context,
      message: 'أكملت اللعبة! $score%',
      emoji: '🏆',
      childName: widget.childName,
      duration: const Duration(seconds: 3),
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '🎉 أحسنت!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statRow('الوقت', '$_secondsElapsed ثانية'),
              _statRow('المحاولات', '$_attempts'),
              _statRow('الأخطاء', '$_mistakes'),
              _statRow('النتيجة', '$score%'),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                icon: const Icon(Icons.replay),
                label: const Text('العب مرة أخرى'),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        title: 'لعبة المطابقة 🎴',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'لعبة جديدة',
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
                _infoChip('⏱️', '$_secondsElapsed ث'),
                _infoChip('🎯', '$_matches/4'),
                _infoChip('❌', '$_mistakes'),
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
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCard(
    _Card card,
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

class _Card {
  final String emoji;
  final bool matched;
  final bool flipped;

  const _Card({
    required this.emoji,
    this.matched = false,
    this.flipped = false,
  });

  _Card copyWith({bool? matched, bool? flipped}) => _Card(
        emoji: emoji,
        matched: matched ?? this.matched,
        flipped: flipped ?? this.flipped,
      );
}