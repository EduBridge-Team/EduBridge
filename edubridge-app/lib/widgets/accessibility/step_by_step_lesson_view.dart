part of 'step_by_step_lesson.dart';

extension _StepByStepLessonStateView on _StepByStepLessonState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    if (widget.steps.isEmpty) {
      return Scaffold(
        appBar: JisrAppBar(title: widget.lessonTitle),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: AdaptiveText(context.l10n.stepLessonEmpty, enableTap: false),
        )),
      );
    }
    if (_loadingPosition) {
      return Scaffold(appBar: JisrAppBar(title: widget.lessonTitle),
          body: const Center(child: CircularProgressIndicator()));
    }
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
              Semantics(
                liveRegion: true,
                child: Text(
                context.l10n.stepLessonPosition(_currentStep + 1, widget.steps.length),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                        _stepTitle(step),
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
                        child: AdaptiveText(
                          step.content,
                          speechLanguageCode: _contentLanguage(step),
                          textAlign: TextAlign.center,
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
                                      context.l10n.stepLessonExample,
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

              AdaptiveButton(
                label: context.l10n.stepLessonListen,
                icon: Icons.volume_up,
                enableReadOnTap: false,
                onPressed: _readCurrentStep,
              ),
              const SizedBox(height: 12),
              Row(children: [
                if (_currentStep > 0) ...[
                  Expanded(child: AdaptiveButton(
                    label: context.l10n.stepLessonPrevious,
                    style: AdaptiveButtonStyle.outlined,
                    onPressed: _previousStep,
                  )),
                  const SizedBox(width: 12),
                ],
                Expanded(child: AdaptiveButton(
                  label: _currentStep == widget.steps.length - 1
                      ? context.l10n.stepLessonFinish : context.l10n.stepLessonNext,
                  onPressed: _nextStep,
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
