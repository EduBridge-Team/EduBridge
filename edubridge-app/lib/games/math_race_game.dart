// لعبة سباق الحساب — للأعمار 7-14
import 'dart:async';
import '../l10n/l10n.dart';
import '../features/games/application/game_question_factory.dart';
import '../features/games/domain/arithmetic_question.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../services/accessibility_service.dart';
import '../utils/adaptive_feedback_policy.dart';
import '../widgets/accessibility/visual_celebration.dart';

class MathRaceGame extends StatefulWidget {
  final String childName;
  final int age;

  const MathRaceGame({super.key, required this.childName, required this.age});

  @override
  State<MathRaceGame> createState() => _MathRaceGameState();
}

class _MathRaceGameState extends State<MathRaceGame> {
  final _questions = GameQuestionFactory();
  late ArithmeticQuestion _question;
  late List<int> _options;
  int _score = 0;
  int _wrong = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _finishing = false;

  AccessibilityProfile get _profile => AccessibilityService.instance.profile.value;
  bool get _noPressure => !AdaptiveFeedbackPolicy(_profile).allowTaskDeadline;

  @override
  void initState() {
    super.initState();
    _newQuestion();
    AccessibilityService.instance.profile.addListener(_profileChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finishing || _noPressure ||
          (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      if (_timeLeft <= 1) {
        setState(() => _timeLeft = 0);
        _onFinish();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _profileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    AccessibilityService.instance.profile.removeListener(_profileChanged);
    super.dispose();
  }

  void _newQuestion() {
    _question = _questions.arithmetic(widget.age);
    _options = _questions.arithmeticChoices(_question);
  }

  Future<void> _check(int picked) async {
    if (_finishing) return;
    if (picked == _question.answer) {
      setState(() => _score++);
      AdaptiveHelper.hapticFeedback();
      if (mounted) setState(() => _newQuestion());
    } else {
      setState(() => _wrong++);
      AdaptiveHelper.hapticFeedback();
    }
  }

  Future<void> _onFinish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    final totalAnswers = _score + _wrong;
    final scorePercent = totalAnswers == 0 ? 0 : ((_score / totalAnswers) * 100).round();
    try {
      await GameProgressService.instance.record(scorePercent);
      if (!mounted) return;
      await VisualCelebration.show(context,
        message: context.l10n.mathCorrectCount(_score), emoji: '➕', childName: widget.childName);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mathSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: BrandAppBar(
        title: Text(context.l10n.mathRaceTitle),
        actions: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .45),
            child: TextButton(
              onPressed: _finishing ? null : _onFinish,
              child: Text(_finishing ? context.l10n.saving : context.l10n.mathFinish,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Wrap(
              alignment: WrapAlignment.spaceAround, spacing: 12, runSpacing: 8,
              children: [
                Text('⭐ $_score',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('❌ $_wrong',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (_noPressure)
                  Text(context.l10n.mathUntimed,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (!_noPressure)
                  Text('⏱️ $_timeLeft',
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: _timeLeft < 15 ? Colors.red : null,
                      )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(_question.expression, textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 64, fontWeight: FontWeight.bold,
                        color: Color(0xFF12283A),
                      ))),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 2,
              children: options.map((opt) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2842B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _check(opt),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text('$opt',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                );
              }).toList(),
            ),
          ),
        ],
      ))))),
    );
  }
}