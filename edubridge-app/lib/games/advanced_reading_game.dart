import 'package:flutter/material.dart';
import '../features/games/application/game_question_factory.dart';
import '../features/games/domain/quiz_session.dart';
import '../services/game_progress_service.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

class AdvancedReadingGame extends StatefulWidget {
  final String childName;
  const AdvancedReadingGame({super.key, required this.childName});
  @override
  State<AdvancedReadingGame> createState() => _AdvancedReadingGameState();
}

class _AdvancedReadingGameState extends State<AdvancedReadingGame> {
  late final QuizSession _session;

  @override
  void initState() {
    super.initState();
    _session = GameQuestionFactory().reading();
  }


  void _choose(int option) {
    final correct = _session.answer(option);
    if (correct == null) return;
    setState(() {});
    TtsService.instance.speakLine(correct ? 'ممتاز، فهمت النص جيداً' : 'ارجع للنص وابحث عن الفكرة الأساسية');
    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      if (_session.finished) {
        await GameProgressService.instance.record(_session.scorePercent);
        await VisualCelebration.show(context, message: 'فهم قرائي رائع! ${_session.correctAnswers} من ${_session.totalRounds}', emoji: '📚', childName: widget.childName, duration: const Duration(seconds: 3));
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
      appBar: AppBar(title: const Text('القراءة المتقدمة 📚')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(value: _session.roundNumber / _session.totalRounds),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(item.passage!, style: const TextStyle(fontSize: 19, height: 1.8)))),
          TextButton.icon(onPressed: () => TtsService.instance.speakLine(item.passage!), icon: const Icon(Icons.volume_up_outlined), label: const Text('استمع إلى النص')),
          const SizedBox(height: 16),
          Text(item.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(item.choices.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(onPressed: _session.answered ? null : () => _choose(i), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(item.choices[i], style: const TextStyle(fontSize: 16)))),
          )),
        ],
      ),
    );
  }
}