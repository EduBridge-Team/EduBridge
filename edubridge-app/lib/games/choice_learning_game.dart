import 'dart:async';
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/game_progress_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'learning_rounds.dart';

enum LearningTopic { colors, shapes, numbers }

class ChoiceLearningGame extends StatefulWidget {
  const ChoiceLearningGame({super.key, required this.topic,
    required this.childName, this.age});
  final LearningTopic topic;
  final String childName;
  final int? age;
  @override
  State<ChoiceLearningGame> createState() => _ChoiceLearningGameState();
}

class _ChoiceLearningGameState extends State<ChoiceLearningGame> {
  static const _colors = [
    ('أحمر', Color(0xFFE53935)), ('أزرق', Color(0xFF1E88E5)),
    ('أخضر', Color(0xFF43A047)), ('أصفر', Color(0xFFFDD835)),
    ('بنفسجي', Color(0xFF8E24AA)), ('برتقالي', Color(0xFFFB8C00)),
  ];
  static const _shapes = [
    ('مثلث', '🔺', 'له ثلاثة أضلاع'), ('مربع', '🟦', 'له أربعة أضلاع متساوية'),
    ('دائرة', '⚫', 'شكل مستدير بلا زوايا'), ('نجمة', '⭐', 'لها خمسة رؤوس'),
    ('قلب', '❤️', 'شكل نعبّر به عن المحبة'), ('سداسي', '⬡', 'له ستة أضلاع'),
  ];
  static const _digits = ['١', '٢', '٣', '٤', '٥', '٦'];
  LearningRounds? _rounds;
  bool _easy = true;
  bool _sound = true;
  bool _saving = false;
  bool _saved = false;
  String? _saveError;
  String _feedback = '';

  bool get _isColors => widget.topic == LearningTopic.colors;
  bool get _isShapes => widget.topic == LearningTopic.shapes;
  String get _title => _isColors ? 'لعبة الألوان' : _isShapes ? 'لعبة الأشكال' : 'لعبة الأرقام';
  String _label(int index) => _isColors ? _colors[index].$1 : _isShapes ? _shapes[index].$1 : _digits[index];
  String get _question => widget.topic == LearningTopic.numbers
    ? 'كم تفاحة ترى؟' : 'أين ${_label(_rounds!.target)}؟';

  @override
  void initState() {
    super.initState();
    _easy = widget.age == null || widget.age! <= 6;
  }

  @override
  void dispose() {
    unawaited(_stopSpeech());
    super.dispose();
  }

  Future<void> _stopSpeech() async {
    try { await TtsService.instance.stop(); } catch (_) {}
  }

  Future<void> _speak(String text) async {
    if (!_sound) return;
    try { await TtsService.instance.speakLine(text); }
    catch (_) { /* Visual instructions remain available without a speech engine. */ }
  }

  void _start() {
    setState(() {
      _rounds = LearningRounds(itemCount: 6, totalRounds: _easy ? 6 : 8,
        optionCount: _easy ? 3 : 4);
      _feedback = '';
      _saving = false;
      _saved = false;
      _saveError = null;
    });
    unawaited(_speak(_question));
  }

  void _choose(int index) {
    final result = _rounds!.choose(index);
    if (result == null) return;
    setState(() => _feedback = result
      ? 'أحسنت! ${_label(index)}، اختيار صحيح.'
      : 'محاولة جيدة! جرّب اختيارًا آخر، أو استخدم التلميح.');
    unawaited(_speak(_feedback));
    if (_rounds!.finished) unawaited(_save());
  }

  void _hint() {
    _rounds!.hint();
    final target = _rounds!.target;
    setState(() => _feedback = _isShapes ? _shapes[target].$3
      : _isColors ? 'ابحث عن اللون ${_label(target)}؛ أضفنا إطارًا حوله.'
      : 'عدّ التفاحات واحدة واحدة: ${_digits.take(target + 1).join('، ')}.');
    unawaited(_speak(_feedback));
  }

  void _next() {
    if (!_rounds!.next()) return;
    setState(() => _feedback = '');
    unawaited(_speak(_question));
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() { _saving = true; _saveError = null; });
    try {
      await GameProgressService.instance.record(_rounds!.scorePercent);
      if (!mounted) return;
      setState(() => _saved = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveError = 'تعذّر حفظ النتيجة. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AccessibilityProfile>(
    valueListenable: AccessibilityService.instance.applicationProfile,
    builder: (context, profile, _) {
      final reduced = profile.reducedAnimations || MediaQuery.of(context).disableAnimations;
      return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
        appBar: JisrAppBar(title: _title),
        body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
            child: AnimatedSwitcher(duration: reduced ? Duration.zero : const Duration(milliseconds: 220),
              child: _rounds == null ? _intro() : _rounds!.finished ? _summary()
                : _play(profile, reduced),
            ))))),
      ));
    },
  );

  Widget _panel(List<Widget> children, {required String id}) => Card(
    key: ValueKey(id), child: Padding(padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)));

  Widget _intro() => _panel([
    const Icon(Icons.school_outlined, size: 64, color: AppColors.brandBlue),
    const SizedBox(height: 16), Text('هيا نتعلم يا ${widget.childName}!',
      textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12), Text(widget.topic == LearningTopic.numbers
      ? 'عدّ التفاحات ثم اختر العدد. خذ وقتك، ويمكنك طلب تلميح.'
      : 'تعرّف على ${_isColors ? 'الألوان' : 'الأشكال'} واختر الإجابة. خذ وقتك، ويمكنك المحاولة من جديد.',
      textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.6)),
    const SizedBox(height: 24),
    Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
      ChoiceChip(label: const Text('بداية سهلة • ٣ اختيارات'), selected: _easy,
        onSelected: (_) => setState(() => _easy = true)),
      ChoiceChip(label: const Text('تحدٍ جديد • ٤ اختيارات'), selected: !_easy,
        onSelected: (_) => setState(() => _easy = false)),
    ]),
    const SizedBox(height: 20), _soundToggle(),
    const SizedBox(height: 12), _action('ابدأ اللعب', Icons.play_arrow, _start),
  ], id: 'intro');

  Widget _soundToggle() => SwitchListTile.adaptive(
    title: const Text('قراءة صوتية'), value: _sound,
    onChanged: (value) {
      setState(() => _sound = value);
      if (!value) unawaited(_stopSpeech());
    });

  Widget _play(AccessibilityProfile profile, bool reduced) {
    final game = _rounds!;
    return Column(key: const ValueKey('play'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('الجولة ${game.answered ? game.completed : game.completed + 1} من ${game.totalRounds}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10), LinearProgressIndicator(value: game.completed / game.totalRounds,
        minHeight: 8, semanticsLabel: 'تقدم الجولات'),
      const SizedBox(height: 20),
      Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        if (widget.topic == LearningTopic.numbers)
          Semantics(label: '${game.target + 1} تفاحات', child: ExcludeSemantics(child: Wrap(
            alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
            children: List.generate(game.target + 1, (_) => const Text('🍎', style: TextStyle(fontSize: 46))))))
        else _symbol(game.target, size: 76),
        const SizedBox(height: 16), Text(_question, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        TextButton.icon(onPressed: () => unawaited(_speak(_question)),
          icon: const Icon(Icons.volume_up_outlined), label: const Text('استمع للسؤال')),
      ]))),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 330 || MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 1 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: game.options.map((index) {
          final correct = game.answered && index == game.target;
          final tried = game.tried.contains(index) && !correct;
          final hint = game.hinted && index == game.target;
          return SizedBox(width: width, child: AnimatedContainer(
            duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
              border: Border.all(color: correct ? Colors.green.shade700 : hint ? AppColors.brandBlue
                : Theme.of(context).dividerColor, width: correct || hint ? 3 : 1)),
            child: OutlinedButton(onPressed: game.answered || tried ? null : () => _choose(index),
              style: OutlinedButton.styleFrom(minimumSize: Size(0, profile.extraLargeTouchTargets ? 132 : 108),
                padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Column(children: [
                if (correct) const Icon(Icons.check_circle, color: Colors.green)
                else if (tried) const Icon(Icons.refresh),
                _symbol(index, size: 44), const SizedBox(height: 8),
                if (widget.topic != LearningTopic.numbers) Text(_label(index),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (tried) const Text('جرّب غيره'),
              ])),
          ));
        }).toList());
      }),
      const SizedBox(height: 18),
      Semantics(liveRegion: true, child: Text(_feedback.isEmpty ? 'كل محاولة تساعدك على التعلّم.' : _feedback,
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.6))),
      const SizedBox(height: 12),
      if (game.answered) _action('التالي', Icons.arrow_back, _next)
      else OutlinedButton.icon(onPressed: _hint, icon: const Icon(Icons.lightbulb_outline), label: const Text('تلميح')),
      _soundToggle(),
    ]);
  }

  Widget _symbol(int index, {required double size}) {
    if (_isColors) return Semantics(label: _label(index), child: Container(width: size, height: size,
      decoration: BoxDecoration(color: _colors[index].$2, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26))));
    return Text(_isShapes ? _shapes[index].$2 : _digits[index],
      semanticsLabel: _label(index), style: TextStyle(fontSize: size));
  }

  Widget _summary() => _panel([
    const Icon(Icons.emoji_events_outlined, size: 72, color: AppColors.brandTeal),
    const SizedBox(height: 16), const Text('أحسنت، أكملت الرحلة!', textAlign: TextAlign.center,
      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14), Text('أكملت ${_rounds!.totalRounds} جولات\n'
      '${_rounds!.firstTryCorrect} إجابات صحيحة من أول محاولة بلا تلميح',
      textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, height: 1.8)),
    const SizedBox(height: 12), const Text('التدريب يساعدك على التقدم. لنجرّب مرة أخرى!', textAlign: TextAlign.center),
    if (_saving) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
    if (_saveError != null) ...[
      Text(_saveError!, textAlign: TextAlign.center),
      TextButton(onPressed: _saving ? null : () => unawaited(_save()), child: const Text('إعادة حفظ النتيجة')),
    ],
    const SizedBox(height: 20), _action('العب من جديد', Icons.replay, _saving || !_saved ? null : _start),
    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('العودة للألعاب')),
  ], id: 'summary');

  Widget _action(String text, IconData icon, VoidCallback? onPressed) => FilledButton.icon(
    onPressed: onPressed, icon: Icon(icon), label: Text(text),
    style: FilledButton.styleFrom(padding: const EdgeInsets.all(18),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
}
