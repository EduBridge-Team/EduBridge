import 'package:flutter/material.dart';
import 'game_content.dart';
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
  static const _bank = [
    (text: 'ذهب سامر إلى المكتبة بعد المدرسة ليستعير كتاباً عن الفضاء. اختار كتاباً عن الكواكب وقرأ الفصل الأول في المساء.', q: 'لماذا ذهب سامر إلى المكتبة؟', options: ['ليشتري لعبة', 'ليستعير كتاباً', 'ليتناول الطعام', 'ليلعب كرة القدم'], answer: 1),
    (text: 'زرعت ليان بذور الطماطم في أصيص قرب النافذة، وكانت تسقيها كل صباح. بعد أيام بدأت أوراق صغيرة تظهر.', q: 'ما الذي ساعد البذور على النمو؟', options: ['الماء والعناية', 'الظلام فقط', 'إهمالها', 'نقلها يومياً'], answer: 0),
    (text: 'قرر الصف جمع الورق المستعمل لإعادة تدويره. وضع الطلاب صندوقاً خاصاً بجانب الباب وبدأوا بجمع الأوراق طوال الأسبوع.', q: 'ما هدف الصندوق؟', options: ['جمع الألعاب', 'جمع الأوراق لإعادة التدوير', 'حفظ الطعام', 'تخزين الكتب الجديدة'], answer: 1),
    (text: 'لاحظت مريم أن صديقتها نسيت قلمها، فأعارتها قلماً من حقيبتها. شكرتها صديقتها وأكملتا الدرس.', q: 'كيف ساعدت مريم صديقتها؟', options: ['أعارتها قلماً', 'أخذت حقيبتها', 'أغلقت الدفتر', 'غادرت الصف'], answer: 0),
    (text: 'كان الجو ممطراً صباحاً. حمل خالد مظلته وارتدى معطفه قبل الخروج إلى المدرسة، فوصل وملابسه جافة.', q: 'لماذا حمل خالد مظلته؟', options: ['ليحتمي من المطر', 'ليلعب بها', 'ليحمل كتبه', 'ليحتمي من الشمس'], answer: 0),
    (text: 'سمعت سلمى صوت عصفور قرب النافذة. وضعت له وعاء ماء في مكان آمن، ثم شاهدته يشرب ويطير.', q: 'ماذا وضعت سلمى للعصفور؟', options: ['وعاء ماء', 'كتاباً', 'حقيبة', 'قلم رصاص'], answer: 0),
    (text: 'أراد يوسف إعداد سلطة. غسل الخضار جيداً أولاً، ثم قطعها بمساعدة والده ووضعها في الطبق.', q: 'ماذا فعل يوسف أولاً؟', options: ['غسل الخضار', 'أكل السلطة', 'وضع الطبق', 'قطع الخضار'], answer: 0),
    (text: 'استعار رامي قصة من صديقه، وحافظ عليها نظيفة. بعد أن انتهى من قراءتها أعادها وشكر صديقه.', q: 'ماذا فعل رامي بعد القراءة؟', options: ['أعاد القصة وشكر صديقه', 'مزق القصة', 'أخفى القصة', 'رسم على الصفحات'], answer: 0),
    (text: 'تدرّبت هناء على ركوب الدراجة في الحديقة. ارتدت خوذتها، وساعدتها أختها حتى استطاعت السير وحدها.', q: 'ما الذي ارتدته هناء لحماية رأسها؟', options: ['خوذة', 'وشاحاً', 'قفازاً', 'حذاء'], answer: 0),
    (text: 'زارت العائلة البحر صباحاً. جمع الأطفال النفايات التي تركوها في كيس قبل العودة، فبقي المكان نظيفاً.', q: 'لماذا جمع الأطفال النفايات؟', options: ['ليحافظوا على نظافة المكان', 'ليصنعوا لعبة', 'ليطعموا الأسماك', 'ليملؤوا البحر'], answer: 0),
    (text: 'وضعت المعلمة بذرتين في أصيصين. سقت الأصيص الأول بانتظام وتركت الثاني بلا ماء. نمت النبتة الأولى.', q: 'أي نبتة نمت؟', options: ['النبتة التي سُقيت', 'النبتة بلا ماء', 'لم تنم أي نبتة', 'نمت النبتتان بالتساوي'], answer: 0),
    (text: 'شاهد آدم لوحة تشير إلى أن المكتبة تغلق الساعة الخامسة. وصل الساعة الرابعة، فكان لديه ساعة للقراءة.', q: 'كم وقتاً كان لدى آدم؟', options: ['ساعة واحدة', 'ساعتان', 'ثلاث ساعات', 'يوم كامل'], answer: 0),
  ];
  late final List<({String text, String q, List<String> options, int answer})> _items;

  @override
  void initState() {
    super.initState();
    _items = GameContent.instance.take('reading', _bank, 3, (item) => item.q)
      .map((item) {
        final answer = item.options[item.answer];
        final options = [...item.options]..shuffle();
        return (text: item.text, q: item.q, options: options, answer: options.indexOf(answer));
      }).toList();
  }

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
        await GameProgressService.instance.record(((_score / _items.length) * 100).round());
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