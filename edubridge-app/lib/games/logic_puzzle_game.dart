import 'package:flutter/material.dart';
import '../features/games/application/game_question_factory.dart';
import '../features/games/domain/quiz_session.dart';
import '../services/game_progress_service.dart';
import 'package:flutter/services.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

class LogicPuzzleGame extends StatefulWidget {
  final String childName;
  const LogicPuzzleGame({super.key, required this.childName});
  @override
  State<LogicPuzzleGame> createState() => _LogicPuzzleGameState();
}

class _LogicPuzzleGameState extends State<LogicPuzzleGame> {
  late final QuizSession _session;

  @override
  void initState() {
    super.initState();
    _session = GameQuestionFactory().logic();
  }


  void _choose(int option) {
    final correct = _session.answer(option);
    if (correct == null) return;
    HapticFeedback.mediumImpact();
    setState(() {});
    TtsService.instance.speakLine(correct ? 'إجابة صحيحة' : 'حاول أن تفكر في العلاقة بين المعلومات');
    Future.delayed(const Duration(milliseconds: 850), () async {
      if (!mounted) return;
      if (_session.finished) {
        await GameProgressService.instance.record(_session.scorePercent);
        await VisualCelebration.show(context, message: 'أحسنت! ${_session.correctAnswers} من ${_session.totalRounds}', emoji: '🧠', childName: widget.childName, duration: const Duration(seconds: 3));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _session.next(); });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _session.current;
    return Scaffold(
      appBar: AppBar(title: const Text('لغز المنطق 🧠')),
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
          ],
        ),
      )),
    );
  }
}