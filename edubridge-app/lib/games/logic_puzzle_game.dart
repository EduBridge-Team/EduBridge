import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/tts_service.dart';
import '../utils/logic_game_display.dart';
import '../theme.dart';
import '../features/games/application/game_question_factory.dart';
import '../features/games/domain/quiz_session.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/visual_celebration.dart';
import '../widgets/accessibility/game_round_continuation.dart';

class LogicPuzzleGame extends StatefulWidget {
  final String childName;
  const LogicPuzzleGame({super.key, required this.childName});
  @override
  State<LogicPuzzleGame> createState() => _LogicPuzzleGameState();
}

class _LogicPuzzleGameState extends State<LogicPuzzleGame> {
  late final QuizSession _session;
  bool? _feedback;
  String get _feedbackText => _feedback == true
      ? context.l10n.logicCorrect : context.l10n.logicIncorrect;
  void _speak(String text) {
    if (!AdaptiveHelper.shouldReadOnTap) return;
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
    _session = GameQuestionFactory().logic();
  }


  void _choose(int option) {
    final correct = _session.answer(option);
    if (correct == null) return;
    AdaptiveHelper.hapticFeedback();
    setState(() => _feedback = correct);
    _speak(_feedbackText);
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
        message: context.l10n.logicComplete(_session.correctAnswers, _session.totalRounds),
        emoji: '🧠', childName: widget.childName,
        duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() { _session.next(); _feedback = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = LogicGameDisplay.question(_session.current, context.l10n);
    return Scaffold(
      appBar: BrandAppBar(title: Text(context.l10n.logicTitle),
      ),
      body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: _session.roundNumber / _session.totalRounds),
            const SizedBox(height: 24),
            Text(item.prompt, key: const ValueKey('logic_question'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.5)),
            const SizedBox(height: 24),
            ...List.generate(item.choices.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                key: ValueKey('logic_choice_$i'),
                onPressed: _session.answered ? null : () => _choose(i),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(item.choices[i], style: const TextStyle(fontSize: 17))),
              ),
            )),
            const SizedBox(height: 20),
            Text(context.l10n.logicScore(_session.correctAnswers), textAlign: TextAlign.center),
            if (_feedback != null)
              Semantics(liveRegion: true, child: Text(_feedbackText, textAlign: TextAlign.center)),
            GameRoundContinuation(
              key: ValueKey('round_${_session.roundNumber}'),
              answered: _session.answered,
              delay: const Duration(milliseconds: 850),
              onContinue: _advance,
            ),
          ],
        ),
      )),
    );
  }
}