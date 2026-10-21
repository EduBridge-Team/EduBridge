// لعبة رتّب القصة — للأعمار 6-12
// الطفل يرى صوراً مبعثرة ويجب أن يرتّبها حسب ترتيب الأحداث
import 'dart:math';
import '../l10n/l10n.dart';
import '../services/tts_service.dart';
import '../utils/ordered_game_display.dart';
import 'game_content.dart';
import '../features/games/domain/ordered_round.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/game_progress_service.dart';
import '../utils/adaptive_helper.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessibility/visual_celebration.dart';
import '../widgets/accessibility/game_stat_chip.dart';
import '../widgets/accessibility/game_round_continuation.dart';
import '../utils/adaptive_feedback_policy.dart';

part 'story_sequencer_game_view.dart';

class StorySequencerGame extends StatefulWidget {
  final String childName;
  final int age;

  const StorySequencerGame({
    super.key,
    required this.childName,
    this.age = 8,
  });

  @override
  State<StorySequencerGame> createState() => _StorySequencerGameState();
}

class _StorySequencerGameState extends State<StorySequencerGame> {
  // كل قصة تحتوي على:
  // - emojis: الصور بالترتيب الصحيح
  // - labels: وصف كل صورة
  // - title: عنوان القصة
  static const _stories = [
    (
      title: 'رحلة الدجاجة',
      emojis: ['🥚', '🐣', '🐤', '🐔'],
      labels: ['البيضة', 'الكتكوت', 'الفرخ', 'الدجاجة'],
    ),
    (
      title: 'نموّ الشجرة',
      emojis: ['🌱', '🌿', '🌳', '🍎'],
      labels: ['البذرة', 'النبتة', 'الشجرة', 'الثمرة'],
    ),
    (
      title: 'يوم كامل',
      emojis: ['🌅', '☀️', '🌇', '🌙'],
      labels: ['الصباح', 'الظهر', 'المساء', 'الليل'],
    ),
    (
      title: 'دورة الماء',
      emojis: ['🌊', '☀️', '☁️', '☔'],
      labels: ['البحر', 'التبخّر', 'السحاب', 'المطر'],
    ),
    (
      title: 'رحلة الفراشة',
      emojis: ['🐛', '🍃', '🦋', '🌸'],
      labels: ['اليسروع', 'الورقة', 'الفراشة', 'الزهرة'],
    ),
    (
      title: 'إعداد الطعام',
      emojis: ['🛒', '🥕', '🍳', '🍽️'],
      labels: ['التسوّق', 'الخضار', 'الطبخ', 'الأكل'],
    ),
    (
      title: 'رحلة في السيارة',
      emojis: ['🚗', '🛣️', '⛽', '🏠'],
      labels: ['البداية', 'الطريق', 'الوقود', 'الوصول'],
    ),
    (
      title: 'بناء المنزل',
      emojis: ['🧱', '🏗️', '🏠', '🏡'],
      labels: ['الطوب', 'البناء', 'المنزل', 'الحديقة'],
    ),
  ];

  late List<String> _correctOrder;
  late List<String> _correctLabels;
  late OrderedRound<String> _ordered;
  List<String> get _shuffled => _ordered.choices;
  late String _title;
  List<String> get _userOrder => _ordered.selected;

  bool? _feedback;
  String? _spokenLocale;
  String _display(String value) => OrderedGameDisplay.story(value, context.l10n);
  String get _feedbackText => _feedback == true
      ? context.l10n.sequenceCorrect : context.l10n.sequenceIncorrect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.l10n.localeName;
    if (_spokenLocale != locale) {
      _spokenLocale = locale;
      _speak(context.l10n.storyGameSpokenInstruction(_display(_title)));
    }
  }
  bool _answeredCorrectly = false;
  bool _finishing = false;
  bool _recorded = false;
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  final _rnd = Random();

  // ✅ عدد الجولات حسب العمر
  int get _totalRounds => widget.age <= 8 ? 4 : 6;

  // ✅ عدد البطاقات في كل قصة حسب العمر
  int get _cardCount {
    if (widget.age <= 7) return 3;
    return 4;
  }

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.profile.addListener(_profileChanged);
    _newRound();
  }

  // ═══════════════════════════════════════════════════════
  //  بدء جولة جديدة
  // ═══════════════════════════════════════════════════════
  void _newRound() {
    if (_round >= _totalRounds) {
      return;
    }

    final story = GameContent.instance.pick('stories', _stories, (item) => item.title);

    // خذ عدد البطاقات المناسب للعمر
    final count = _cardCount;
    _correctOrder = story.emojis.take(count).toList();
    _correctLabels = story.labels.take(count).toList();
    _title = story.title;

    _ordered = OrderedRound(_correctOrder, random: _rnd);
    _feedback = null;
    _answeredCorrectly = false;

    // نطق التعليمات
    if (_spokenLocale != null) {
      _speak(context.l10n.storyGameSpokenInstruction(_display(_title)));
    }

    setState(() {});
  }

  void _speak(String text) {
    if (!AdaptiveHelper.shouldReadOnTap) return;
    _read(text);
  }

  void _read(String text) {
    final language = context.l10n.localeName;
    if (AdaptiveHelper.useSlowSpeech) {
      TtsService.instance.speakLineSlow(text, languageCode: language);
    } else {
      TtsService.instance.speakLine(text, languageCode: language);
    }
  }

  void _retry() {
    if (_finishing || _answeredCorrectly) return;
    setState(() {
      _ordered.reset();
      _feedback = null;
    });
    _speak(context.l10n.retry);
  }

  @override
  void dispose() {
    AccessibilityService.instance.profile.removeListener(_profileChanged);
    super.dispose();
  }

  void _profileChanged() {
    if (mounted) setState(() {});
  }


  // ═══════════════════════════════════════════════════════
  //  ضغط على بطاقة
  // ═══════════════════════════════════════════════════════
  void _tapEmoji(String emoji) {
    if (_finishing || _feedback != null || _ordered.complete || _userOrder.contains(emoji)) return;

    AdaptiveHelper.hapticFeedback();
    setState(() => _ordered.selectValue(emoji));

    // هل اكتمل الترتيب؟
    if (_userOrder.length == _correctOrder.length) {
      _check();
    }
  }

  // ═══════════════════════════════════════════════════════
  //  فحص الترتيب
  // ═══════════════════════════════════════════════════════
  void _check() {
    if (!mounted || !_ordered.complete || _feedback != null) return;
    final correct = _ordered.correct;
    setState(() {
      _answeredCorrectly = correct;
      _feedback = correct;
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
    AdaptiveHelper.hapticFeedback();
    _speak(_feedbackText);
  }

  Future<void> _advance() async {
    if (!_answeredCorrectly || _finishing) return;
    if (_round + 1 >= _totalRounds) {
      await _onWin();
    } else {
      setState(() => _round++);
      _newRound();
    }
  }

  // ═══════════════════════════════════════════════════════
  //  عند الفوز
  // ═══════════════════════════════════════════════════════
  Future<void> _onWin() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      if (!_recorded) {
        await GameProgressService.instance.record(((_score / _totalRounds) * 100).round());
        _recorded = true;
      }
      if (!mounted) return;
      await VisualCelebration.show(context, message: context.l10n.storyGameComplete(_score, _totalRounds),
        emoji: '📖', childName: widget.childName, duration: const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _finishing = false);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  //  واجهة المستخدم
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => _buildGame(context);
}
