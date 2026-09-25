
// درس خطوة بخطوة — للإعاقة الذهنية البسيطة
// يقسّم الدرس لخطوات صغيرة + يربط بالحياة اليومية
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
part 'step_by_step_lesson_view.dart';

class LessonStep {
  final String title;
  final String content;
  final String? imageEmoji;
  final String? realLifeExample; // ✅ ربط بالحياة اليومية

  const LessonStep({
    required this.title,
    required this.content,
    this.imageEmoji,
    this.realLifeExample,
  });
}

class StepByStepLesson extends StatefulWidget {
  final String lessonTitle;
  final List<LessonStep> steps;
  final String childName;

  const StepByStepLesson({
    super.key,
    required this.lessonTitle,
    required this.steps,
    required this.childName,
  });

  @override
  State<StepByStepLesson> createState() => _StepByStepLessonState();
}

class _StepByStepLessonState extends State<StepByStepLesson> {
  int _currentStep = 0;

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.profile.value;

  @override
  void initState() {
    super.initState();
    // قراءة الخطوة الأولى بعد تحميل الشاشة
    Future.delayed(const Duration(milliseconds: 600), _readCurrentStep);
  }

  void _readCurrentStep() {
    final step = widget.steps[_currentStep];
    final text = [
      step.title,
      step.content,
      if (step.realLifeExample != null)
        'مثال من الحياة: ${step.realLifeExample}',
    ].join('. ');

    // ✅ نطق بطيء للإعاقة الذهنية
    if (_profile.slowSpeech) {
      TtsService.instance.speakLineSlow(text);
    } else {
      TtsService.instance.speakLine(text);
    }
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _readCurrentStep();
    } else {
      _finishLesson();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _readCurrentStep();
    }
  }

  void _finishLesson() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🎉 أحسنت!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'أكملت درس "${widget.lessonTitle}" بنجاح يا ${widget.childName}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('رائع!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}