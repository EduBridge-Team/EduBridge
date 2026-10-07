import 'package:flutter/material.dart';
import 'game_content.dart';
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
  static final _bank = [
    (q: 'كل الطيور لها أجنحة، والعصفور طائر. ماذا نعرف؟', options: ['للعصفور أجنحة', 'العصفور سمكة', 'لا يملك ريشاً', 'لا شيء'], answer: 0),
    (q: 'إذا كان أحمد أطول من سامر، وسامر أطول من كريم، فمن الأطول؟', options: ['كريم', 'سامر', 'أحمد', 'متساوون'], answer: 2),
    (q: 'يوجد 3 كتب على الطاولة وأضفنا كتابين. كم أصبح العدد؟', options: ['4', '5', '6', '3'], answer: 1),
    (q: 'إذا كانت كل المربعات أشكالاً، وهذا الشكل مربع، فما الصحيح؟', options: ['ليس شكلاً', 'هو شكل', 'هو دائرة', 'لا نعرف'], answer: 1),
    (q: 'بدأ الدرس الساعة 9 وانتهى الساعة 10. كم استغرق؟', options: ['ساعة', 'ساعتان', '30 دقيقة', '3 ساعات'], answer: 0),
    (q: 'ليلى أمام هدى في الصف، وهدى أمام نور. من تقف أولاً؟', options: ['ليلى', 'هدى', 'نور', 'لا نعرف'], answer: 0),
    (q: 'أي شيء لا ينتمي إلى المجموعة: تفاحة، موزة، برتقالة، قلم؟', options: ['تفاحة', 'موزة', 'قلم', 'برتقالة'], answer: 2),
    (q: 'كل الأسماك تعيش في الماء. السردين سمكة. أين يعيش؟', options: ['في الماء', 'فوق الشجرة', 'في الصحراء', 'في المكتبة'], answer: 0),
    (q: 'إذا كان اليوم الثلاثاء، فما اليوم التالي؟', options: ['الاثنين', 'الأربعاء', 'الجمعة', 'الأحد'], answer: 1),
    (q: 'أي شكل ليس له زوايا؟', options: ['المثلث', 'المربع', 'الدائرة', 'المستطيل'], answer: 2),
    for (var a = 1; a <= 9; a++)
      for (var b = 1; b <= 5; b++)
        (q: 'يوجد $a أقلام، وأضفنا $b أقلام. كم أصبح العدد؟',
          options: ['${a + b}', '${a + b + 1}', '${a + b + 2}', '${a + b - 1}'], answer: 0),
    for (var a = 5; a <= 12; a++)
      for (var b = 1; b <= 4; b++)
        (q: 'مع سارة $a ملصقات، أعطت صديقتها $b ملصقات. كم بقي معها؟',
          options: ['${a - b}', '${a - b + 1}', '${a + b}', '${a - b - 1}'], answer: 0),
    for (var start = 1; start <= 6; start++)
      for (var step = 1; step <= 3; step++)
        (q: 'ما العدد التالي: $start، ${start + step}، ${start + step * 2}؟',
          options: ['${start + step * 3}', '${start + step * 3 + 1}', '${start + step * 3 + 2}', '${start + step * 3 - 1}'], answer: 0),

  ];
  late final List<({String q, List<String> options, int answer})> _questions;

  @override
  void initState() {
    super.initState();
    _questions = GameContent.instance.take('logic', _bank, 5, (item) => item.q)
      .map((item) {
        final answer = item.options[item.answer];
        final options = [...item.options]..shuffle();
        return (q: item.q, options: options, answer: options.indexOf(answer));
      }).toList();
  }

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
        await GameProgressService.instance.record(((_score / _questions.length) * 100).round());
        await VisualCelebration.show(context, message: 'أحسنت! $_score من ${_questions.length}', emoji: '🧠', childName: widget.childName, duration: const Duration(seconds: 3));
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
      body: SingleChildScrollView(child: Padding(
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
            const SizedBox(height: 20),
            Text('النتيجة: $_score', textAlign: TextAlign.center),
          ],
        ),
      )),
    );
  }
}