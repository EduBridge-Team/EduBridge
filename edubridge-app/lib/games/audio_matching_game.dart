import '../l10n/l10n.dart';
import '../services/tts_service.dart';
// لعبة مطابقة الأصوات — للأطفال المكفوفين
import 'dart:async';
import 'game_content.dart';
import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../services/encouragement_service.dart';
import '../theme.dart';

class AudioMatchingGame extends StatefulWidget {
  final String childName;

  const AudioMatchingGame({super.key, required this.childName});

  @override
  State<AudioMatchingGame> createState() => _AudioMatchingGameState();
}

class _AudioMatchingGameState extends State<AudioMatchingGame> {
  static const _pairs = [
    ('🐶', 'كلب'),
    ('🐱', 'قطة'),
    ('🐦', 'طائر'),
    ('🐄', 'بقرة'),
    ('🐸', 'ضفدع'), ('🦁', 'أسد'), ('🐘', 'فيل'), ('🐎', 'حصان'),
    ('🚗', 'سيارة'), ('🚲', 'دراجة'), ('🍎', 'تفاحة'), ('🍌', 'موز'),
  ];

  late List<_AudioCard> _cards;
  int? _firstIndex;
  bool _locked = false;
  int _matches = 0;
  bool _resultRecorded = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _speak(String text) => AdaptiveHelper.useSlowSpeech
      ? TtsService.instance.speakLineSlow(text, languageCode: context.l10n.localeName)
      : TtsService.instance.speakLine(text, languageCode: context.l10n.localeName);

  Future<void> _announce(String text) async {
    if (AdaptiveHelper.shouldReadOnTap) await _speak(text);
  }

  String _cardName(String name) => switch (name) {
    'كلب' => context.l10n.audioWordDog,
    'قطة' => context.l10n.audioWordCat,
    'طائر' => context.l10n.audioWordBird,
    'بقرة' => context.l10n.audioWordCow,
    'ضفدع' => context.l10n.audioWordFrog,
    'أسد' => context.l10n.audioWordLion,
    'فيل' => context.l10n.audioWordElephant,
    'حصان' => context.l10n.audioWordHorse,
    'سيارة' => context.l10n.audioWordCar,
    'دراجة' => context.l10n.audioWordBicycle,
    'تفاحة' => context.l10n.audioWordApple,
    'موز' => context.l10n.audioWordBanana,
    _ => name,
  };

  void _startGame() {
    _generation++;
    _resultRecorded = false;
    final selected = GameContent.instance.take('audio_matching', _pairs, 4, (item) => item.$2);
    final all = [...selected, ...selected]..shuffle();
    _cards = all
        .map((p) => _AudioCard(emoji: p.$1, name: p.$2))
        .toList();
    _firstIndex = null;
    _matches = 0;
    _locked = false;

    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation && ModalRoute.of(context)?.isCurrent != false) {
        _announce(context.l10n.audioGameWelcome(widget.childName));
      }
    });

    setState(() {});
  }

  Future<void> _selectCard(int index) async {
    if (_locked || _resultRecorded || _cards[index].matched) return;
    final generation = _generation;
    _locked = true;

    await _speak(_cardName(_cards[index].name));
    if (!mounted || generation != _generation) return;
    AdaptiveHelper.hapticFeedback();

    if (_firstIndex == null) {
      _locked = false;
      _firstIndex = index;
      setState(() {});
      return;
    }

    if (_firstIndex == index) {
      _locked = false;
      return;
    }

    _locked = true;
    final first = _cards[_firstIndex!];
    final second = _cards[index];

    if (first.name == second.name) {
      setState(() {
        _cards[_firstIndex!] =
            _cards[_firstIndex!].copyWith(matched: true);
        _cards[index] = _cards[index].copyWith(matched: true);
        _matches++;
      });

      AdaptiveHelper.hapticFeedback();
      EncouragementService.instance.praiseSuccess();

      if (_matches == 4) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted || generation != _generation) return;
        await _onWin();
      }
    } else {
      AdaptiveHelper.hapticFeedback();
      await _announce(context.l10n.audioGameRetry);
    }

    if (!mounted || generation != _generation) return;
    setState(() {
      _firstIndex = null;
      _locked = false;
    });
  }

  Future<void> _onWin() async {
    if (!mounted || _resultRecorded) return;
    _resultRecorded = true;
    AdaptiveHelper.hapticFeedback();

    await GameProgressService.instance.record(100);

    if (!mounted) return;
    await _announce(
      context.l10n.audioGameWinSpeech(widget.childName),
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          scrollable: true,
          title: Text(context.l10n.audioGameWinTitle,
              textAlign: TextAlign.center),
          content: Text(
            context.l10n.audioGameReplayHint,
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startGame();
                },
                child: Text(context.l10n.matchingPlayAgain),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.audioGameTitle),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: JisrColors.of(context).tintTeal,
            child: Row(
              children: [
                Icon(Icons.volume_up, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.audioGameInstructions,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
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
                itemBuilder: (context, i) => _buildAudioCard(i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(int index) {
    final card = _cards[index];
    final c = JisrColors.of(context);
    final isSelected = _firstIndex == index;

    return Semantics(
      button: true,
      label: card.matched ? context.l10n.audioGameMatchedCard : context.l10n.audioGameCard(_cardName(card.name)),
      child: GestureDetector(
        onTap: () => _selectCard(index),
        child: Container(
          decoration: BoxDecoration(
            color: card.matched
                ? c.tintGreen
                : isSelected
                    ? AppColors.orange.withValues(alpha: 0.2)
                    : AppColors.teal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: card.matched
                  ? c.success
                  : isSelected
                      ? AppColors.orange
                      : c.line,
              width: card.matched || isSelected ? 3 : 2,
            ),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FittedBox(fit: BoxFit.scaleDown, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                card.matched ? Icons.check_circle : Icons.volume_up,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                card.matched ? context.l10n.audioGameComplete : context.l10n.audioGameListen,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )),
          ),
        ),
      ),
    );
  }
}

class _AudioCard {
  final String emoji;
  final String name;
  final bool matched;

  const _AudioCard({
    required this.emoji,
    required this.name,
    this.matched = false,
  });

  _AudioCard copyWith({bool? matched}) =>
      _AudioCard(emoji: emoji, name: name, matched: matched ?? this.matched);
}