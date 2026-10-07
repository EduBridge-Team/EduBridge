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
                    sw('تحسين لقارئ الشاشة', 'دعم NVDA و JAWS و VoiceOver',
                        p.screenReaderOptimized,
                        (v) => _set(p.copyWith(screenReaderOptimized: v)), enabled: _canChange),
                    sw('وصف تفصيلي للصور', 'وصف صوتي لكل صورة (Alt Text)',
                        p.detailedAltText,
                        (v) => _set(p.copyWith(detailedAltText: v)), enabled: _canChange),
                    sw('وصف صوتي للفيديوهات', 'صوت يشرح ما يحدث في الفيديو',
                        p.audioDescriptions,
                        (v) => _set(p.copyWith(audioDescriptions: v)), enabled: _canChange),
                    sw('اختصارات لوحة المفاتيح', 'Tab للتنقل وEnter لتفعيل الاختيار',
                        p.keyboardShortcuts,
                        (v) => _set(p.copyWith(keyboardShortcuts: v)), enabled: _canChange),
                    sw('واجهة نصية فقط', 'إزالة كل الرسومات غير الضرورية',
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
                    sw('ترجمة نصية للفيديوهات', 'Captions لكل محتوى مرئي',
                        p.videoCaptions,
                        (v) => _set(p.copyWith(videoCaptions: v)), enabled: _canChange),
                    sw('وصف الأصوات البيئية', 'مثل [موسيقى] [باب يطرق]',
                        p.soundDescriptions,
                        (v) => _set(p.copyWith(soundDescriptions: v)), enabled: _canChange),
                    sw('ترجمة لغة الإشارة', 'عرض مترجم لغة الإشارة',
                        p.signLanguageTranslation,
                        (v) => _set(p.copyWith(signLanguageTranslation: v)), enabled: _canChange),
                    sw('إشعارات بصرية', 'بدل الأصوات — إشعارات مرئية',
                        p.visualNotifications,
                        (v) => _set(p.copyWith(visualNotifications: v)), enabled: _canChange),
                    sw('تنبيهات بوميض', 'وميض ملوّن للإشعارات المهمة',
                        p.flashAlerts, (v) => _set(p.copyWith(flashAlerts: v)), enabled: _canChange),
                    sw('اهتزاز قوي', 'للتنبيهات والنجاح', p.vibrationAlerts,
                        (v) => _set(p.copyWith(vibrationAlerts: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: 'ميزات اضطرابات النطق واللغة',
                  icon: AppIcons.speech,
                  color: AppColors.orangeDeep,
                  c: c,
                  children: [
                    sw('تحويل الكلام إلى نص', 'Speech-to-Text للكتابة',
                        p.voiceToText,
                        (v) => _set(p.copyWith(voiceToText: v)), enabled: _canChange),
                    sw('اقتراح كلمات', 'Word Prediction أثناء الكتابة',
                        p.wordPrediction,
                        (v) => _set(p.copyWith(wordPrediction: v)), enabled: _canChange),
                    sw('تواصل بالصور', 'AAC — اختيار صور بدل الكلام',
                        p.pictureCommunication,
                        (v) => _set(p.copyWith(pictureCommunication: v)), enabled: _canChange),
                    sw('جمل قصيرة جداً', '8-10 كلمات كحد أقصى',
                        p.shortSentences,
                        (v) => _set(p.copyWith(shortSentences: v)), enabled: _canChange),
                    sw('وقت غير محدود', 'بدون ضغط زمني أو مؤقّتات',
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
                    sw('تحكم صوتي', 'Voice Control لكل الأوامر',
                        p.voiceControl, (v) => _set(p.copyWith(voiceControl: v)), enabled: _canChange),
                    sw('تتبع العين', 'غير متاح حاليًا',
                        false, (_) {}, enabled: false),
                    sw('مفاتيح تبديل', 'Switch Control للأجهزة المساعدة',
                        p.switchControl,
                        (v) => _set(p.copyWith(switchControl: v)), enabled: _canChange),
                    sw('بدون تفاعل مؤقّت', 'لا شيء يختفي بسرعة',
                        p.noTimedInteractions,
                        (v) => _set(p.copyWith(noTimedInteractions: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: 'ميزات الإعاقات الذهنية والنطورية',
                  icon: AppIcons.cognitive,
                  color: AppColors.purple,
                  c: c,
                  children: [
                    sw('وضع الأيقونات فقط', 'بدون نصوص — أيقونات كبيرة',
                        p.iconOnlyMode, (v) => _set(p.copyWith(iconOnlyMode: v)), enabled: _canChange),
                    sw('لغة مبسّطة جداً', 'كلمات وجمل قصيرة وسهلة',
                        p.verySimpleLanguage,
                        (v) => _set(p.copyWith(verySimpleLanguage: v)), enabled: _canChange),
                    sw('تكرار المحتوى', 'إعادة تلقائية للمفاهيم',
                        p.repetitionMode,
                        (v) => _set(p.copyWith(repetitionMode: v)), enabled: _canChange),
                    sw('نظام المكافآت', 'نجوم وشارات للتشجيع', p.rewardSystem,
                        (v) => _set(p.copyWith(rewardSystem: v)), enabled: _canChange),
                    sw('روتين ثابت', 'نفس الترتيب في كل جلسة',
                        p.routineStructure,
                        (v) => _set(p.copyWith(routineStructure: v)), enabled: _canChange),
                    sw('حد أقصى 3 خيارات', 'تقليل عدد الخيارات المعروضة',
                        p.maxOptionsCount3,
                        (v) => _set(p.copyWith(maxOptionsCount3: v)), enabled: _canChange),
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
