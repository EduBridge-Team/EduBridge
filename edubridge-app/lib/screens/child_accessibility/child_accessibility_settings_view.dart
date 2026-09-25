part of 'child_accessibility_settings_screen.dart';

extension ChildAccessibilitySettingsScreenStateView on _ChildAccessibilitySettingsScreenState {
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
                const SizedBox(height: 20),
                buildSectionTitle('نوع الإعاقة', c),
                const SizedBox(height: 8),
                buildDisabilitySelector(
                  c: c,
                  selectedValue: _selectedDisability,
                  onTap: _openDisabilityPicker,
                ),
                if (_selectedDisability == 'أخرى') ...[
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
                        (v) => _set(p.copyWith(screenReaderOptimized: v))),
                    sw('وصف تفصيلي للصور', 'وصف صوتي لكل صورة (Alt Text)',
                        p.detailedAltText,
                        (v) => _set(p.copyWith(detailedAltText: v))),
                    sw('وصف صوتي للفيديوهات', 'صوت يشرح ما يحدث في الفيديو',
                        p.audioDescriptions,
                        (v) => _set(p.copyWith(audioDescriptions: v))),
                    sw('اختصارات لوحة المفاتيح', 'Alt+1, Alt+2... للتنقل السريع',
                        p.keyboardShortcuts,
                        (v) => _set(p.copyWith(keyboardShortcuts: v))),
                    sw('واجهة نصية فقط', 'إزالة كل الرسومات غير الضرورية',
                        p.textOnlyMode, (v) => _set(p.copyWith(textOnlyMode: v))),
                    sw('مؤشر فأرة كبير', 'مؤشر واضح ومكبّر',
                        p.largeMouseCursor,
                        (v) => _set(p.copyWith(largeMouseCursor: v))),
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
                        (v) => _set(p.copyWith(videoCaptions: v))),
                    sw('وصف الأصوات البيئية', 'مثل [موسيقى] [باب يطرق]',
                        p.soundDescriptions,
                        (v) => _set(p.copyWith(soundDescriptions: v))),
                    sw('ترجمة لغة الإشارة', 'عرض مترجم لغة الإشارة',
                        p.signLanguageTranslation,
                        (v) => _set(p.copyWith(signLanguageTranslation: v))),
                    sw('إشعارات بصرية', 'بدل الأصوات — إشعارات مرئية',
                        p.visualNotifications,
                        (v) => _set(p.copyWith(visualNotifications: v))),
                    sw('تنبيهات بوميض', 'وميض ملوّن للإشعارات المهمة',
                        p.flashAlerts, (v) => _set(p.copyWith(flashAlerts: v))),
                    sw('اهتزاز قوي', 'للتنبيهات والنجاح', p.vibrationAlerts,
                        (v) => _set(p.copyWith(vibrationAlerts: v))),
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
                        (v) => _set(p.copyWith(voiceToText: v))),
                    sw('اقتراح كلمات', 'Word Prediction أثناء الكتابة',
                        p.wordPrediction,
                        (v) => _set(p.copyWith(wordPrediction: v))),
                    sw('تواصل بالصور', 'AAC — اختيار صور بدل الكلام',
                        p.pictureCommunication,
                        (v) => _set(p.copyWith(pictureCommunication: v))),
                    sw('جمل قصيرة جداً', '8-10 كلمات كحد أقصى',
                        p.shortSentences,
                        (v) => _set(p.copyWith(shortSentences: v))),
                    sw('وقت غير محدود', 'بدون ضغط زمني أو مؤقّتات',
                        p.unlimitedTime,
                        (v) => _set(p.copyWith(unlimitedTime: v))),
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
                        (v) => _set(p.copyWith(keyboardOnlyNavigation: v))),
                    sw('تحكم صوتي', 'Voice Control لكل الأوامر',
                        p.voiceControl, (v) => _set(p.copyWith(voiceControl: v))),
                    sw('تتبع العين', 'Eye Tracking — تحكم بالنظر',
                        p.eyeTrackingOptimized,
                        (v) => _set(p.copyWith(eyeTrackingOptimized: v))),
                    sw('مفاتيح تبديل', 'Switch Control للأجهزة المساعدة',
                        p.switchControl,
                        (v) => _set(p.copyWith(switchControl: v))),
                    sw('بدون تفاعل مؤقّت', 'لا شيء يختفي بسرعة',
                        p.noTimedInteractions,
                        (v) => _set(p.copyWith(noTimedInteractions: v))),
                  ],
                ),

                buildFeatureSection(
                  title: 'ميزات الإعاقات الذهنية والنطورية',
                  icon: AppIcons.cognitive,
                  color: AppColors.purple,
                  c: c,
                  children: [
                    sw('وضع الأيقونات فقط', 'بدون نصوص — أيقونات كبيرة',
                        p.iconOnlyMode, (v) => _set(p.copyWith(iconOnlyMode: v))),
                    sw('لغة مبسّطة جداً', 'كلمات وجمل قصيرة وسهلة',
                        p.verySimpleLanguage,
                        (v) => _set(p.copyWith(verySimpleLanguage: v))),
                    sw('تكرار المحتوى', 'إعادة تلقائية للمفاهيم',
                        p.repetitionMode,
                        (v) => _set(p.copyWith(repetitionMode: v))),
                    sw('نظام المكافآت', 'نجوم وشارات للتشجيع', p.rewardSystem,
                        (v) => _set(p.copyWith(rewardSystem: v))),
                    sw('روتين ثابت', 'نفس الترتيب في كل جلسة',
                        p.routineStructure,
                        (v) => _set(p.copyWith(routineStructure: v))),
                    sw('حد أقصى 3 خيارات', 'تقليل عدد الخيارات المعروضة',
                        p.maxOptionsCount3,
                        (v) => _set(p.copyWith(maxOptionsCount3: v))),
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
                        (v) => _set(p.copyWith(extraLargeTouchTargets: v))),
                    sw('تقليل الحركات', 'أنيميشن هادئ', p.reducedAnimations,
                        (v) => _set(p.copyWith(reducedAnimations: v))),
                    sw('نطق تلقائي عند اللمس', 'قراءة صوتية لكل عنصر',
                        p.autoReadOnTap,
                        (v) => _set(p.copyWith(autoReadOnTap: v))),
                    sw('نطق بطيء', 'للتأتأة والإعاقة الذهنية', p.slowSpeech,
                        (v) => _set(p.copyWith(slowSpeech: v))),
                    sw('تباين عالٍ', 'خلفية سوداء وألوان صريحة',
                        p.highContrast, (v) => _set(p.copyWith(highContrast: v))),
                    sw('وضع الهدوء الحسي', 'إسكات الأصوات والاهتزازات',
                        p.sensoryCalmMode,
                        (v) => _set(p.copyWith(sensoryCalmMode: v))),
                    sw('زر طوارئ', 'اتصال سريع بالأهل', p.emergencyButton,
                        (v) => _set(p.copyWith(emergencyButton: v))),
                  ],
                ),

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(AppIcons.refresh),
                  label: const Text('إعادة الضبط'),
                  onPressed: () {
                    setState(() => _selectedDisability = null);
                    AccessibilityService.instance.applyRecommendedForChild(
                        widget.childId, DisabilityType.none);
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
