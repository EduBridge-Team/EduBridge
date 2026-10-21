import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/tts_service.dart';
import '../utils/reading_game_display.dart';
import '../theme.dart';
import '../features/games/application/game_question_factory.dart';
import '../features/games/domain/quiz_session.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/visual_celebration.dart';
import '../widgets/accessibility/game_round_continuation.dart';

class AdvancedReadingGame extends StatefulWidget {
  final String childName;
  const AdvancedReadingGame({super.key, required this.childName});
  @override
  State<AdvancedReadingGame> createState() => _AdvancedReadingGameState();
}

class _AdvancedReadingGameState extends State<AdvancedReadingGame> {
  late final QuizSession _session;
  bool? _feedback;
  String get _feedbackText => _feedback == true
      ? context.l10n.readingCorrect : context.l10n.readingIncorrect;

  void _read(String text) {
    if (AdaptiveHelper.useSlowSpeech) {
      TtsService.instance.speakLineSlow(text, languageCode: context.l10n.localeName);
    } else {
      TtsService.instance.speakLine(text, languageCode: context.l10n.localeName);
    }
  }
  bool _resultRecorded = false;

  @override
  void initState() {
    super.initState();
    _session = GameQuestionFactory().reading();
  }


  void _choose(int option) {
    final correct = _session.answer(option);
    if (correct == null) return;
    setState(() => _feedback = correct);
    if (AdaptiveHelper.shouldReadOnTap) _read(_feedbackText);
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (_session.finished) {
      if (!_resultRecorded) {
        await GameProgressService.instance.record(_session.scorePercent);
        _resultRecorded = true;
      }
      if (!mounted) return;
      await VisualCelebration.show(context,
        message: context.l10n.readingComplete(_session.correctAnswers, _session.totalRounds),
        emoji: '📚', childName: widget.childName,
        duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() { _session.next(); _feedback = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = ReadingGameDisplay.question(_session.current, context.l10n);
    return Scaffold(
      appBar: BrandAppBar(title: Text(context.l10n.readingTitle),
      ),
      body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LinearProgressIndicator(value: _session.roundNumber / _session.totalRounds),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(item.passage!, key: const ValueKey('reading_passage'), style: const TextStyle(fontSize: 19, height: 1.8)))),
          TextButton.icon(onPressed: () => _read(item.passage!), icon: const Icon(Icons.volume_up_outlined), label: Text(context.l10n.readingListen)),
          const SizedBox(height: 16),
          Text(item.prompt, key: const ValueKey('reading_question'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(item.choices.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(key: ValueKey('reading_choice_$i'), onPressed: _session.answered ? null : () => _choose(i), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(item.choices[i], style: const TextStyle(fontSize: 16)))),
          )),
            if (_feedback != null)
              Semantics(liveRegion: true, child: Text(_feedbackText, textAlign: TextAlign.center)),
            GameRoundContinuation(
              key: ValueKey('round_${_session.roundNumber}'),
              answered: _session.answered,
              delay: const Duration(milliseconds: 900),
              onContinue: _advance,
            ),
        ],
      ))),
    );
  }
}