
// درس خطوة بخطوة — للإعاقة الذهنية البسيطة
// يقسّم الدرس لخطوات صغيرة + يربط بالحياة اليومية
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';

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
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final step = widget.steps[_currentStep];
    final progress = (_currentStep + 1) / widget.steps.length;

    return Scaffold(
      backgroundColor: c.card,
      appBar: JisrAppBar(title: widget.lessonTitle),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ─── شريط التقدّم ───
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 20,
                  backgroundColor: c.line,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الخطوة ${_currentStep + 1} من ${widget.steps.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // ─── محتوى الخطوة ───
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // صورة توضيحية
                      if (step.imageEmoji != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: c.tintTeal,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            step.imageEmoji!,
                            style: const TextStyle(fontSize: 110),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // العنوان
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // المحتوى
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.line, width: 1.5),
                        ),
                        child: Text(
                          step.content,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.6,
                          ),
                        ),
                      ),

                      // ✅ مثال من الحياة اليومية
                      if (step.realLifeExample != null &&
                          _profile.realLifeLinking) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.tintGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡',
                                  style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مثال من الحياة',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: c.onTint,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      step.realLifeExample!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: c.onTint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── زر الاستماع ───
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.volume_up, size: 32),
                  label: const Text(
                    'استمع مرة أخرى',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _readCurrentStep,
                ),
              ),
              const SizedBox(height: 12),

              // ─── أزرار التنقّل ───
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: SizedBox(
                        height: 70,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back, size: 28),
                          label: const Text(
                            'السابق',
                            style: TextStyle(fontSize: 18),
                          ),
                          onPressed: _previousStep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 70,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(
                          _currentStep == widget.steps.length - 1
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                          size: 28,
                        ),
                        label: Text(
                          _currentStep == widget.steps.length - 1
                              ? 'أكملت!'
                              : 'التالي',
                          style: const TextStyle(fontSize: 18),
                        ),
                        onPressed: _nextStep,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}