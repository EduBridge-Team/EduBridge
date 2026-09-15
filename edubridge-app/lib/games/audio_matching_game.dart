// لعبة مطابقة الأصوات — للأطفال المكفوفين
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encouragement_service.dart';
import '../services/tts_service.dart';
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
  ];

  late List<_AudioCard> _cards;
  int? _firstIndex;
  bool _locked = false;
  int _matches = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    final all = [..._pairs, ..._pairs]..shuffle();
    _cards = all
        .map((p) => _AudioCard(emoji: p.$1, name: p.$2))
        .toList();
    _firstIndex = null;
    _matches = 0;
    _locked = false;

    TtsService.instance.speakLine(
      'مرحباً ${widget.childName}! المس أي بطاقة لتسمع اسمها، ثم ابحث عن زوجها',
    );

    setState(() {});
  }

  Future<void> _selectCard(int index) async {
    if (_locked || _cards[index].matched) return;

    await TtsService.instance.speakLine(_cards[index].name);
    HapticFeedback.lightImpact();

    if (_firstIndex == null) {
      _firstIndex = index;
      setState(() {});
      return;
    }

    if (_firstIndex == index) return;

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

      HapticFeedback.heavyImpact();
      await TtsService.instance.speakLine('صحيح! أحسنت');
      EncouragementService.instance.praiseSuccess();

      if (_matches == 4) {
        await Future.delayed(const Duration(milliseconds: 500));
        _onWin();
      }
    } else {
      HapticFeedback.mediumImpact();
      await TtsService.instance.speakLine('حاول مرة أخرى');
    }

    setState(() {
      _firstIndex = null;
      _locked = false;
    });
  }

  Future<void> _onWin() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();

    await TtsService.instance.speakLine(
      'مذهل يا ${widget.childName}! أكملت اللعبة بنجاح',
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🏆 أكملت اللعبة!',
              textAlign: TextAlign.center),
          content: const Text(
            'اضغط على "العب مرة أخرى" لتسمع اللعبة من جديد',
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
                child: const Text('العب مرة أخرى'),
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
      appBar: JisrAppBar(title: 'لعبة الأصوات 🔊'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: JisrColors.of(context).tintTeal,
            child: const Row(
              children: [
                Icon(Icons.volume_up, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'المس أي بطاقة لتسمع اسمها، ثم اختر زوجها',
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
      label: card.matched ? 'بطاقة مكتملة' : 'بطاقة ${card.name}',
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                card.matched ? Icons.check_circle : Icons.volume_up,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                card.matched ? 'مكتملة' : 'المس للاستماع',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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