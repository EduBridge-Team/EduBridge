import 'package:flutter/material.dart';
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
  String _feedback = '';
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
    setState(() => _feedback = correct ? 'إجابة صحيحة' : 'حاول أن تفكر في العلاقة بين المعلومات');
    if (AdaptiveHelper.shouldReadOnTap) AdaptiveHelper.speak(_feedback);
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
        message: 'أحسنت! ${_session.correctAnswers} من ${_session.totalRounds}',
        emoji: '🧠', childName: widget.childName,
        duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() { _session.next(); _feedback = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _session.current;
    return Scaffold(
      appBar: BrandAppBar(title: const Text('لغز المنطق 🧠')),
      body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: _session.roundNumber / _session.totalRounds),
            const SizedBox(height: 24),
            Text(item.prompt, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.5)),
            const SizedBox(height: 24),
            ...List.generate(item.choices.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: _session.answered ? null : () => _choose(i),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(item.choices[i], style: const TextStyle(fontSize: 17))),
              ),
            )),
            const SizedBox(height: 20),
            Text('النتيجة: ${_session.correctAnswers}', textAlign: TextAlign.center),
            if (_feedback.isNotEmpty)
              Semantics(liveRegion: true, child: Text(_feedback, textAlign: TextAlign.center)),
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