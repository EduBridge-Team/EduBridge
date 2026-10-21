import '../../l10n/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../utils/content_speech_language.dart';

// درس خطوة بخطوة — للإعاقة الذهنية البسيطة
// يقسّم الدرس لخطوات صغيرة + يربط بالحياة اليومية
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../services/lesson_resume_service.dart';
import 'package:flutter/material.dart';
import 'adaptive_text.dart';
import 'adaptive_button.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
part 'step_by_step_lesson_view.dart';

class LessonStep {
  final String title;
  final String content;
  final String? imageEmoji;
  final int? generatedNumber;
  final String? realLifeExample; // ✅ ربط بالحياة اليومية

  const LessonStep({
    required this.title,
    required this.content,
    this.imageEmoji,
    this.realLifeExample,
    this.generatedNumber,
  });
}

class StepByStepLesson extends StatefulWidget {
  final String lessonTitle;
  final List<LessonStep> steps;
  final String childName;
  final int? childId;
  final int? lessonId;
  final String? contentLanguageCode;

  const StepByStepLesson({
    super.key,
    required this.lessonTitle,
    required this.steps,
    required this.childName,
    this.childId,
    this.lessonId,
    this.contentLanguageCode,
  });

  @override
  State<StepByStepLesson> createState() => _StepByStepLessonState();
}

class _StepByStepLessonState extends State<StepByStepLesson> {
  int _currentStep = 0;
  Timer? _initialReading;
  bool _showingCompletion = false;
  bool _loadingPosition = true;
  int? _owner;
  Future<void> _saveTail = Future<void>.value();
  final _resume = const LessonResumeService();
  String get _version => jsonEncode(widget.steps.map((step) =>
      [step.title, step.content, step.realLifeExample]).toList());

  Future<void> _restorePosition() async {
    try {
      if (widget.childId != null && widget.lessonId != null) {
        _owner = await ApiService.getUserId();
        if (_owner != null) {
          final step = await _resume.load(_owner!, widget.childId!,
              widget.lessonId!, _version, widget.steps.length);
          if (!mounted) return;
          setState(() => _currentStep = step);
        }
      }
    } catch (_) {
      // Storage failure must not block reading.
    }
    if (!mounted) return;
    setState(() => _loadingPosition = false);
    _initialReading = Timer(const Duration(milliseconds: 600), _autoReadCurrentStep);
  }

  void _savePosition() {
    final owner = _owner;
    if (owner == null || widget.childId == null || widget.lessonId == null) return;
    final step = _currentStep;
    final version = _version;
    _saveTail = _saveTail.then((_) async {
      if (await ApiService.getUserId() != owner) return;
      await _resume.save(owner, widget.childId!, widget.lessonId!, version, step);
    }).catchError((Object _) {});
  }


  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  @override
  void initState() {
    super.initState();
    // قراءة الخطوة الأولى بعد تحميل الشاشة
    _restorePosition();
  }

  @override
  void dispose() {
    _initialReading?.cancel();
    super.dispose();
  }

  void _autoReadCurrentStep() {
    if (!mounted || !_profile.autoReadOnTap || _profile.sensoryCalmMode) return;
    _readCurrentStep();
  }

  String _stepTitle(LessonStep step) => step.generatedNumber == null
      ? step.title : context.l10n.childLessonsStep(step.generatedNumber.toString());

  String _contentLanguage(LessonStep step) => ContentSpeechLanguage.resolve(
      '${step.content} ${step.realLifeExample ?? ''}',
      override: widget.contentLanguageCode, fallback: context.l10n.localeName);

  void _readCurrentStep() {
    if (!mounted || widget.steps.isEmpty) return;
    _initialReading?.cancel();
    final step = widget.steps[_currentStep];
    final language = _contentLanguage(step);
    final contentStrings = lookupAppLocalizations(Locale(language.startsWith('en') ? 'en' : 'ar'));
    final text = [
      _stepTitle(step),
      step.content,
      if (step.realLifeExample != null && _profile.realLifeLinking)
        contentStrings.stepLessonSpokenExample(step.realLifeExample!),
    ].join('. ');

    // ✅ نطق بطيء للإعاقة الذهنية
    if (_profile.slowSpeech) {
      TtsService.instance.speakLineSlow(text, languageCode: language);
    } else {
      TtsService.instance.speakLine(text, languageCode: language);
    }
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _savePosition();
      _autoReadCurrentStep();
    } else {
      _finishLesson();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _savePosition();
      _autoReadCurrentStep();
    }
  }

  Future<void> _finishLesson() async {
    if (_showingCompletion || widget.steps.isEmpty) return;
    _showingCompletion = true;
    _initialReading?.cancel();
    final finish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AdaptiveText(
          dialogContext.l10n.stepLessonEffort,
          textAlign: TextAlign.center,
          enableTap: false,
        ),
        content: SingleChildScrollView(child: AdaptiveText(
          dialogContext.l10n.stepLessonComplete(widget.lessonTitle),
          textAlign: TextAlign.center,
          enableTap: false,
        )),
        actions: [
          AdaptiveButton(
            label: dialogContext.l10n.stepLessonReview,
            style: AdaptiveButtonStyle.outlined,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          const SizedBox(height: 8),
          AdaptiveButton(
            label: dialogContext.l10n.stepLessonBack,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _showingCompletion = false;
    if (finish == true) {
      Navigator.pop(context);
    } else if (finish == false) {
      setState(() => _currentStep = 0);
      _savePosition();
      _autoReadCurrentStep();
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}