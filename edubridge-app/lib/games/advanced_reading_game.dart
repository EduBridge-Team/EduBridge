import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../widgets/accessibility/visual_celebration.dart';

class AdvancedReadingGame extends StatefulWidget {
  final String childName;
  const AdvancedReadingGame({super.key, required this.childName});
  @override
  State<AdvancedReadingGame> createState() => _AdvancedReadingGameState();
}

class _AdvancedReadingGameState extends State<AdvancedReadingGame> {
  static const _items = [
    (text: 'ذهب سامر إلى المكتبة بعد المدرسة ليستعير كتاباً عن الفضاء. اختار كتاباً عن الكواكب وقرأ الفصل الأول في المساء.', q: 'لماذا ذهب سامر إلى المكتبة؟', options: ['ليشتري لعبة', 'ليستعير كتاباً', 'ليتناول الطعام', 'ليلعب كرة القدم'], answer: 1),
    (text: 'زرعت ليان بذور الطماطم في أصيص قرب النافذة، وكانت تسقيها كل صباح. بعد أيام بدأت أوراق صغيرة تظهر.', q: 'ما الذي ساعد البذور على النمو؟', options: ['الماء والعناية', 'الظلام فقط', 'إهمالها', 'نقلها يومياً'], answer: 0),
    (text: 'قرر الصف جمع الورق المستعمل لإعادة تدويره. وضع الطلاب صندوقاً خاصاً بجانب الباب وبدأوا بجمع الأوراق طوال الأسبوع.', q: 'ما هدف الصندوق؟', options: ['جمع الألعاب', 'جمع الأوراق لإعادة التدوير', 'حفظ الطعام', 'تخزين الكتب الجديدة'], answer: 1),
  ];
  int _index = 0;
  int _score = 0;
  bool _locked = false;

  void _choose(int option) {
    if (_locked) return;
    final correct = option == _items[_index].answer;
    setState(() { _locked = true; if (correct) _score++; });
    TtsService.instance.speakLine(correct ? 'ممتاز، فهمت النص جيداً' : 'ارجع للنص وابحث عن الفكرة الأساسية');
    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      if (_index == _items.length - 1) {
        await VisualCelebration.show(context, message: 'فهم قرائي رائع! $_score من ${_items.length}', emoji: '📚', childName: widget.childName, duration: const Duration(seconds: 3));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _index++; _locked = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('القراءة المتقدمة 📚')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(value: (_index + 1) / _items.length),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(item.text, style: const TextStyle(fontSize: 19, height: 1.8)))),
          TextButton.icon(onPressed: () => TtsService.instance.speakLine(item.text), icon: const Icon(Icons.volume_up_outlined), label: const Text('استمع إلى النص')),
          const SizedBox(height: 16),
          Text(item.q, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(item.options.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(onPressed: _locked ? null : () => _choose(i), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(item.options[i], style: const TextStyle(fontSize: 16)))),
          )),
        ],
      ),
    );
  }
}