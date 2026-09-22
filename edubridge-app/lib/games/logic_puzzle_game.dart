import 'package:flutter/material.dart';
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
  static const _questions = [
    (q: 'كل الطيور لها أجنحة، والعصفور طائر. ماذا نعرف؟', options: ['للعصفور أجنحة', 'العصفور سمكة', 'لا يملك ريشاً', 'لا شيء'], answer: 0),
    (q: 'إذا كان أحمد أطول من سامر، وسامر أطول من كريم، فمن الأطول؟', options: ['كريم', 'سامر', 'أحمد', 'متساوون'], answer: 2),
    (q: 'يوجد 3 كتب على الطاولة وأضفنا كتابين. كم أصبح العدد؟', options: ['4', '5', '6', '3'], answer: 1),
    (q: 'إذا كانت كل المربعات أشكالاً، وهذا الشكل مربع، فما الصحيح؟', options: ['ليس شكلاً', 'هو شكل', 'هو دائرة', 'لا نعرف'], answer: 1),
    (q: 'بدأ الدرس الساعة 9 وانتهى الساعة 10. كم استغرق؟', options: ['ساعة', 'ساعتان', '30 دقيقة', '3 ساعات'], answer: 0),
  ];
  int _index = 0;
  int _score = 0;
  bool _locked = false;

  void _choose(int option) {
    if (_locked) return;
    final correct = option == _questions[_index].answer;
    HapticFeedback.mediumImpact();
    setState(() { _locked = true; if (correct) _score++; });
    TtsService.instance.speakLine(correct ? 'إجابة صحيحة' : 'حاول أن تفكر في العلاقة بين المعلومات');
    Future.delayed(const Duration(milliseconds: 850), () async {
      if (!mounted) return;
      if (_index == _questions.length - 1) {
        await VisualCelebration.show(context, message: 'أحسنت! ' + _score.toString() + ' من ' + _questions.length.toString(), emoji: '🧠', childName: widget.childName, duration: const Duration(seconds: 3));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _index++; _locked = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('لغز المنطق 🧠')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_index + 1) / _questions.length),
            const SizedBox(height: 24),
            Text(item.q, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.5)),
            const SizedBox(height: 24),
            ...List.generate(item.options.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: _locked ? null : () => _choose(i),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(item.options[i], style: const TextStyle(fontSize: 17))),
              ),
            )),
            const Spacer(),
            Text('النتيجة: ' + _score.toString(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}