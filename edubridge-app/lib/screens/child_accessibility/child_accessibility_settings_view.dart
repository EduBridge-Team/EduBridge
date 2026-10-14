part of 'child_accessibility_settings_screen.dart';

extension _ChildAccessibilitySettingsScreenStateView on _ChildAccessibilitySettingsScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return AdaptiveWrapper(
      screenTitle: 'إعدادات ${widget.childName}',
      child: Scaffold(
        appBar: JisrAppBar(title: 'إعدادات ${widget.childName}'),
        body: ValueListenableBuilder<AccessibilityProfile>(
          valueListenable: AccessibilityService.instance.profile,
          builder: (context, _, __) {
            final p = _p;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                buildInfoBanner(c, widget.childName),
                if (!_canEdit)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('للعرض فقط — التعديل متاح للمختص المعيّن للطفل.'),
                  ),
                const SizedBox(height: 20),
                buildSectionTitle('نوع الإعاقة', c),
                const SizedBox(height: 8),
                buildDisabilitySelector(
                  c: c,
                  selectedValue: _selectedDisability,
                  onTap: _canChange ? _openDisabilityPicker : null,
                ),
                if (_canEdit && _selectedDisability == 'أخرى') ...[
                  const SizedBox(height: 12),
                  buildCustomDisabilityBox(
                    c: c,
                    controller: _customNameCtrl,
                    onSave: _applyCustom,
                  ),
                ],
                const SizedBox(height: 24),

                buildFeatureSection(
                  title: 'ميزات الإعاقات البصرية',
                  icon: AppIcons.blind,
                  color: AppColors.brandBlue,
                  c: c,
                  children: [
                    sw('تحسين لقارئ الشاشة', 'تحسين تسميات العناصر لقارئ الشاشة على الجهاز',
                        p.screenReaderOptimized,
                        (v) => _set(p.copyWith(screenReaderOptimized: v)), enabled: _canChange),
                    sw('وصف تفصيلي للصور', 'قراءة وصف صورة الدرس عند توفره، بالضغط عليها',
                        p.detailedAltText,
                        (v) => _set(p.copyWith(detailedAltText: v)), enabled: _canChange),
                    sw('وصف صوتي للفيديوهات', 'قراءة الوصف إذا كان مضافاً لفيديو الدرس',
                        p.audioDescriptions,
                        (v) => _set(p.copyWith(audioDescriptions: v)), enabled: _canChange),
                    sw('اختصارات لوحة المفاتيح', 'Tab للتنقل وEnter لتفعيل الاختيار',
                        p.keyboardShortcuts,
                        (v) => _set(p.copyWith(keyboardShortcuts: v)), enabled: _canChange),
                    sw('واجهة نصية فقط', 'عرض وصف صور الدرس بدل تحميل الصور',
                        p.textOnlyMode, (v) => _set(p.copyWith(textOnlyMode: v)), enabled: _canChange),
                    sw('مؤشر فأرة كبير', 'يمكن ضبط حجم المؤشر من إعدادات الجهاز',
                        false, (_) {}, enabled: false),
                  ],
                ),

                buildFeatureSection(
                  title: 'ميزات الإعاقات السمعية',
                  icon: AppIcons.deaf,
                  color: AppColors.pink,
                  c: c,
                  children: [
                    sw('ترجمة نصية للفيديوهات', 'عرض ملف الترجمة إذا كان مضافاً لفيديو الدرس',
                        p.videoCaptions,
                        (v) => _set(p.copyWith(videoCaptions: v)), enabled: _canChange),
                    sw('وصف الأصوات البيئية', 'عرض أوصاف مثل [موسيقى] إذا كانت مكتوبة بملف ترجمة الفيديو',
                        p.soundDescriptions, (v) => _set(p.copyWith(soundDescriptions: v)), enabled: _canChange),
                    sw('ترجمة لغة الإشارة', 'عرض فيديو الإشارة إذا كان مضافاً للدرس',
                        p.signLanguageTranslation,
                        (v) => _set(p.copyWith(signLanguageTranslation: v)), enabled: _canChange),
                    sw('إشعارات بصرية', 'إظهار حالة التشغيل والتوقف بشكل واضح فوق فيديو الدرس',
                        p.visualNotifications, (v) => _set(p.copyWith(visualNotifications: v)), enabled: _canChange),
                    sw('تنبيهات بوميض', 'وميض ملوّن للإشعارات المهمة',
                        p.flashAlerts, (v) => _set(p.copyWith(flashAlerts: v)), enabled: _canChange),
                    sw('اهتزاز للتنبيهات', 'اهتزاز عند النجاح وتأكيد الطوارئ حسب الإعدادات', p.vibrationAlerts,
                        (v) => _set(p.copyWith(vibrationAlerts: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: 'ميزات اضطرابات النطق واللغة',
                  icon: AppIcons.speech,
                  color: AppColors.orangeDeep,
                  c: c,
                  children: [
                    sw('تحويل الكلام إلى نص', 'كتابة إجابة الواجب بالصوت؛ يتطلب دعم العربية على الجهاز',
                        p.voiceToText,
                        (v) => _set(p.copyWith(voiceToText: v)), enabled: _canChange),
                    sw('اقتراح كلمات', 'اقتراح كلمات تواصل عامة أثناء كتابة إجابة الواجب',
                        p.wordPrediction,
                        (v) => _set(p.copyWith(wordPrediction: v)), enabled: _canChange),
                    sw('تواصل بالصور', 'إضافة عبارات من بطاقات رمزية إلى إجابة الواجب',
                        p.pictureCommunication,
                        (v) => _set(p.copyWith(pictureCommunication: v)), enabled: _canChange),
                    sw('جمل قصيرة جداً', 'تقسيم عرض النص لأسطر قصيرة بدون حذف المحتوى',
                        p.shortSentences,
                        (v) => _set(p.copyWith(shortSentences: v)), enabled: _canChange),
                    sw('وقت غير محدود', 'تعطيل مؤقّت المهمة؛ الاستراحة تبقى محدودة',
                        p.unlimitedTime,
                        (v) => _set(p.copyWith(unlimitedTime: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: 'ميزات الإعاقات الحركية والعصبية',
                  icon: AppIcons.motor,
                  color: AppColors.brandBlue,
                  c: c,
                  children: [
                    sw('تحكم بلوحة المفاتيح فقط', 'بدون حاجة للفأرة',
                        p.keyboardOnlyNavigation,
                        (v) => _set(p.copyWith(keyboardOnlyNavigation: v)), enabled: _canChange),
                    sw('تحكم صوتي', 'غير منفذ في شاشات الطفل حالياً — الإعداد المحفوظ لا يغيّرها',
                        p.voiceControl, (_) {}, enabled: false),
                    sw('تتبع العين', 'غير متاح حاليًا',
                        false, (_) {}, enabled: false),
                    sw('مفاتيح تبديل', 'تنقل بلوحة المفاتيح؛ الجهاز المساعد يحتاج إعداداً على الجهاز',
                        p.switchControl,
                        (v) => _set(p.copyWith(switchControl: v)), enabled: _canChange),
                    sw('بدون تفاعل مؤقّت', 'التنبيهات والتشجيع يبقيان حتى الإغلاق؛ الاستراحة محدودة',
                        p.noTimedInteractions,
                        (v) => _set(p.copyWith(noTimedInteractions: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: 'ميزات الإعاقات الذهنية والنمائية',
                  icon: AppIcons.cognitive,
                  color: AppColors.purple,
                  c: c,
                  children: [
                    sw('قراءة خطوة بخطوة', 'إظهار زر أقرأ بسهولة لتقسيم نص الدرس دون حذف محتواه',
                        p.stepByStepLessons,
                        (v) => _set(p.copyWith(stepByStepLessons: v)), enabled: _canChange),
                    sw('أزرار برموز', 'إخفاء نص الزر عند توفر رمز، مع إبقاء تعليمات الدرس',
                        p.iconOnlyMode, (v) => _set(p.copyWith(iconOnlyMode: v)), enabled: _canChange),
                    sw('لغة مبسّطة جداً', 'كلمات وجمل قصيرة وسهلة',
                        p.verySimpleLanguage,
                        (v) => _set(p.copyWith(verySimpleLanguage: v)), enabled: _canChange),
                    sw('تكرار المحتوى', 'قراءة عنوان الشاشة مرة عند الدخول إذا كان النطق مفعّلاً',
                        p.repetitionMode,
                        (v) => _set(p.copyWith(repetitionMode: v)), enabled: _canChange),
                    sw('نظام المكافآت', 'نجوم وشارات للتشجيع', p.rewardSystem,
                        (v) => _set(p.copyWith(rewardSystem: v)), enabled: _canChange),
                    sw('روتين ثابت', 'ترتيب ثابت للدروس وخطوات جلسة واضحة',
                        p.routineStructure, (v) => _set(p.copyWith(routineStructure: v)), enabled: _canChange),
                    sw('حد أقصى 3 خيارات', 'عرض 3 بطاقات تواصل بالمرة مع الوصول لباقي البطاقات',
                        p.maxOptionsCount3,
                        (v) => _set(p.copyWith(maxOptionsCount3: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: 'الاستراحة',
                  icon: Icons.pause_circle_outline,
                  color: AppColors.teal,
                  c: c,
                  children: [
                    sw('استراحات أثناء التعلم', 'اقتراح استراحة خلال الدروس',
                        p.brainBreaksEnabled,
                        (v) => _set(p.copyWith(brainBreaksEnabled: v)), enabled: _canChange),
                    buildDurationSetting(
                      title: 'الفترة بين الاستراحات',
                      subtitle: 'اقتراح استراحة بعد هذه المدة من التعلم.',
                      value: p.brainBreakIntervalMinutes,
                      choices: const [5, 10, 15, 20, 30, 45, 60, 90, 120],
                      unit: 'دقيقة',
                      onChanged: _canChange && p.brainBreaksEnabled
                          ? (value) => _set(p.copyWith(brainBreakIntervalMinutes: value)) : null,
                    ),
                    buildDurationSetting(
                      title: 'مدة الاستراحة',
                      subtitle: p.noTimedInteractions || p.noTimers
                          ? 'العدّاد مخفي عن الطفل، والاستراحة تنتهي حسب المدة المحددة.'
                          : 'يمكن للطفل إنهاؤها مبكراً أو تمديدها مرتين، كل مرة 30 ثانية.',
                      value: p.brainBreakDurationSeconds,
                      choices: const [15, 30, 60, 90, 120],
                      unit: 'ثانية',
                      onChanged: _canChange
                          ? (value) => _set(p.copyWith(brainBreakDurationSeconds: value)) : null,
                    ),
                  ],
                ),

                buildFeatureSection(
                  title: 'وقت التعلم',
                  icon: Icons.timer_outlined,
                  color: AppColors.brandBlue,
                  c: c,
                  children: [
                    sw('مؤقّت المهمة', 'عرض مؤقّت بصري أو سمعي حسب إعدادات الطفل',
                        p.visualTimerEnabled,
                        (v) => _set(p.copyWith(visualTimerEnabled: v)), enabled: _canChange),
                    buildDurationSetting(
                      title: 'مدة مؤقّت المهمة',
                      subtitle: p.unlimitedTime || p.noTimers || p.noTimedInteractions
                          ? 'المؤقّت معطّل حسب إعدادات الوقت الحالية؛ تبقى المدة محفوظة.'
                          : 'المدة المتاحة قبل اقتراح استراحة.',
                      value: p.timerRenewalMinutes,
                      choices: const [1, 3, 5, 10, 15, 20, 30, 45, 60],
                      unit: 'دقيقة',
                      onChanged: _canChange && p.visualTimerEnabled &&
                          !p.unlimitedTime && !p.noTimers && !p.noTimedInteractions
                          ? (value) => _set(p.copyWith(timerRenewalMinutes: value)) : null,
                    ),
                    sw('إخفاء العدّادات', 'إخفاء عدّاد المهمة والاستراحة؛ الاستراحة تبقى محدودة',
                        p.noTimers,
                        (v) => _set(p.copyWith(noTimers: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: 'خصائص عامة',
                  icon: AppIcons.settings,
                  color: AppColors.muted,
                  c: c,
                  children: [
                    sw('أزرار ضخمة جداً', '≥ 88 بكسل',
                        p.extraLargeTouchTargets,
                        (v) => _set(p.copyWith(extraLargeTouchTargets: v)), enabled: _canChange),
                    sw('تقليل الحركات', 'أنيميشن هادئ', p.reducedAnimations,
                        (v) => _set(p.copyWith(reducedAnimations: v)), enabled: _canChange),
                    sw('تجنّب الوميض', 'تعطيل مؤثرات الحركة والوميض في العناصر المتكيفة',
                        p.noFlashing,
                        (v) => _set(p.copyWith(noFlashing: v)), enabled: _canChange),
                    sw('نطق تلقائي عند اللمس', 'قراءة صوتية لكل عنصر',
                        p.autoReadOnTap,
                        (v) => _set(p.copyWith(autoReadOnTap: v)), enabled: _canChange),
                    sw('نطق بطيء', 'للتأتأة والإعاقة الذهنية', p.slowSpeech,
                        (v) => _set(p.copyWith(slowSpeech: v)), enabled: _canChange),
                    sw('حدود أوضح', 'حدود أكثر سماكة مع الحفاظ على ألوان EduBridge',
                        p.highContrast, (v) => _set(p.copyWith(highContrast: v)), enabled: _canChange),
                    sw('وضع الهدوء الحسي', 'إسكات الأصوات والاهتزازات',
                        p.sensoryCalmMode,
                        (v) => _set(p.copyWith(sensoryCalmMode: v)), enabled: _canChange),
                    sw('زر طوارئ', 'اتصال سريع بالأهل', p.emergencyButton,
                        (v) => _set(p.copyWith(emergencyButton: v)), enabled: _canChange),
                  ],
                ),

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.tune),
                  label: const Text('تطبيق إعدادات مقترحة'),
                  onPressed: _canChange ? _applyRecommendations : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(AppIcons.refresh),
                  label: const Text('إعادة الضبط'),
                  onPressed: !_canChange ? null : () {
                    _refreshState(() => _selectedDisability = null);
                    _set(const AccessibilityProfile(type: DisabilityType.none));
                  },
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  
  }
}
