part of 'step_by_step_lesson.dart';

extension _StepByStepLessonStateView on _StepByStepLessonState {
  Widget buildView(BuildContext context) {
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
