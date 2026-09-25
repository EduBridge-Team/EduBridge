// Presentation helpers for the children accessibility overview.
part of 'children_accessibility_overview_screen.dart';

extension _ChildrenAccessibilityOverviewWidgets on _ChildrenAccessibilityOverviewScreenState {
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_children.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      itemCount: _children.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildHeader();
        return _buildChildCard(_children[i - 1], i - 1);
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        backgroundColor:
            AdaptiveHelper.accentColor(context).withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(
              AppIcons.info,
              size: AdaptiveHelper.iconSize,
              color: AdaptiveHelper.accentColor(context),
            ),
            SizedBox(width: AdaptiveHelper.spacing / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdaptiveText(
                    'خصص التكييف لكل طفل',
                    type: AdaptiveTextType.body,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: AdaptiveHelper.spacing / 4),
                  const AdaptiveText(
                    'كل طفل له احتياجات مختلفة. اضغط على طفلك لتخصيص تجربته.',
                    type: AdaptiveTextType.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(Map child, int index) {
    final name = (child['name'] ?? '').toString();
    final id = child['id'] as int;
    final age = child['age'] ?? '?';

    final profile = AccessibilityService.instance.profileForChild(id) ??
        const AccessibilityProfile(type: DisabilityType.none);

    final color = AppColors.kidPalette[index % AppColors.kidPalette.length];
    final label = profile.type == DisabilityType.other
        ? (profile.customDisabilityName ?? 'مخصّص')
        : (disabilityLabels[profile.type] ?? 'بدون تكييف');

    final activeFeatures = _countActiveFeatures(profile);

    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        onTap: () => _openChildSettings(child),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AdaptiveHelper.avatarSize,
                  height: AdaptiveHelper.avatarSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '؟',
                    style: TextStyle(
                      fontSize: AdaptiveHelper.avatarSize * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveText(
                        name,
                        type: AdaptiveTextType.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: AdaptiveHelper.spacing / 4),
                      AdaptiveText(
                        'العمر: $age سنة',
                        type: AdaptiveTextType.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: AdaptiveHelper.accentColor(context),
                  size: AdaptiveHelper.iconSize,
                ),
              ],
            ),

            SizedBox(height: AdaptiveHelper.spacing),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AdaptiveHelper.spacing / 1.5,
                vertical: AdaptiveHelper.spacing / 2,
              ),
              decoration: BoxDecoration(
                color: AdaptiveHelper.accentColor(context)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AdaptiveHelper.accentColor(context)
                      .withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.specialist,
                    size: AdaptiveHelper.iconSize,
                    color: AdaptiveHelper.accentColor(context),
                  ),
                  SizedBox(width: AdaptiveHelper.spacing / 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdaptiveText(
                          'نوع الإعاقة',
                          type: AdaptiveTextType.label,
                          color: AdaptiveHelper.accentColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 2),
                        AdaptiveText(
                          label,
                          type: AdaptiveTextType.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AdaptiveHelper.spacing / 2),

            if (activeFeatures > 0) ...[
              Row(
                children: [
                  Icon(
                    AppIcons.check,
                    size: AdaptiveHelper.iconSize * 0.7,
                    color: AppColors.green,
                  ),
                  SizedBox(width: AdaptiveHelper.spacing / 3),
                  AdaptiveText(
                    '$activeFeatures ميزة تكييف مُفعّلة',
                    type: AdaptiveTextType.caption,
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: AdaptiveHelper.spacing / 2),
            ],

            Wrap(
              spacing: AdaptiveHelper.spacing / 3,
              runSpacing: AdaptiveHelper.spacing / 3,
              children: _buildFeatureBadges(profile),
            ),

            SizedBox(height: AdaptiveHelper.spacing),

            AdaptiveButton(
              label: 'تخصيص التكييف',
              icon: AppIcons.settings,
              backgroundColor: AdaptiveHelper.accentColor(context),
              onPressed: () => _openChildSettings(child),
            ),
          ],
        ),
      ),
    );
  }

  int _countActiveFeatures(AccessibilityProfile p) {
    int count = 0;
    final features = [
      p.brainBreaksEnabled,
      p.visualTimerEnabled,
      p.reducedAnimations,
      p.predictableTimeline,
      p.sensoryCalmMode,
      p.extraLargeTouchTargets,
      p.autoReadOnTap,
      p.simpleIconsGrid,
      p.highContrast,
      p.gestureNavigationEnabled,
      p.visualAlertsEnabled,
      p.slowSpeech,
      p.rhythmReading,
      p.stepByStepLessons,
      p.realLifeLinking,
      p.colorSymbols,
      p.colorPatterns,
      p.colorFiltersEnabled,
      p.noFlashing,
      p.calmColors,
      p.emergencyButton,
      p.noTimers,
      p.speechExercises,
      p.screenReaderOptimized,
      p.textOnlyMode,
      p.largeMouseCursor,
      p.keyboardOnlyNavigation,
      p.eyeTrackingOptimized,
      p.switchControl,
      p.noTimedInteractions,
      p.iconOnlyMode,
      p.verySimpleLanguage,
      p.repetitionMode,
      p.rewardSystem,
      p.routineStructure,
      p.maxOptionsCount3,
      p.shortSentences,
      p.detailedAltText,
      p.audioDescriptions,
      p.videoCaptions,
      p.soundDescriptions,
      p.signLanguageTranslation,
      p.visualNotifications,
      p.flashAlerts,
      p.vibrationAlerts,
      p.voiceToText,
      p.wordPrediction,
      p.pictureCommunication,
      p.voiceControl,
      p.keyboardShortcuts,
    ];
    for (final f in features) {
      if (f) count++;
    }
    return count;
  }

  List<Widget> _buildFeatureBadges(AccessibilityProfile p) {
    final badges = <Widget>[];

    void addBadge(IconData icon, String label, Color color) {
      badges.add(
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AdaptiveHelper.spacing / 2,
            vertical: AdaptiveHelper.spacing / 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize - 5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (p.videoCaptions) addBadge(AppIcons.captions, 'ترجمات', AppColors.pink);
    if (p.signLanguageTranslation) {
      addBadge(AppIcons.signLanguage, 'لغة إشارة', AppColors.pink);
    }
    if (p.vibrationAlerts) addBadge(Icons.vibration, 'اهتزاز', AppColors.pink);
    if (p.detailedAltText) {
      addBadge(AppIcons.volumeUp, 'وصف صوتي', AppColors.brandBlue);
    }
    if (p.audioDescriptions) {
      addBadge(AppIcons.speech, 'وصف فيديو', AppColors.brandBlue);
    }
    if (p.pictureCommunication) {
      addBadge(AppIcons.aac, 'تواصل بالصور', AppColors.purple);
    }
    if (p.voiceToText) addBadge(AppIcons.mic, 'كتابة صوتية', AppColors.purple);
    if (p.slowSpeech) addBadge(Icons.speed, 'نطق بطيء', AppColors.orangeDeep);
    if (p.voiceControl) {
      addBadge(AppIcons.mic, 'تحكم صوتي', AppColors.brandBlue);
    }
    if (p.keyboardOnlyNavigation || p.keyboardShortcuts) {
      addBadge(Icons.keyboard, 'لوحة مفاتيح', AppColors.brandBlue);
    }
    if (p.verySimpleLanguage) {
      addBadge(AppIcons.info, 'لغة مبسّطة', AppColors.purple);
    }
    if (p.iconOnlyMode) addBadge(AppIcons.aac, 'أيقونات', AppColors.purple);
    if (p.rewardSystem) {
      addBadge(AppIcons.starFilled, 'مكافآت', AppColors.yellow);
    }
    if (p.shortSentences) {
      addBadge(Icons.short_text, 'جمل قصيرة', AppColors.purple);
    }
    if (p.extraLargeTouchTargets) {
      addBadge(Icons.touch_app, 'أزرار كبيرة', AppColors.brandBlue);
    }
    if (p.autoReadOnTap) {
      addBadge(AppIcons.volumeUp, 'نطق باللمس', AppColors.brandTeal);
    }
    if (p.highContrast) addBadge(AppIcons.theme, 'تباين عالٍ', AppColors.brandBlue);
    if (p.noTimers) addBadge(Icons.pause, 'بدون وقت', AppColors.green);
    if (p.reducedAnimations) {
      addBadge(Icons.slow_motion_video, 'حركة هادئة', AppColors.brandTeal);
    }
    if (p.emergencyButton) {
      addBadge(AppIcons.emergency, 'طوارئ', AppColors.red);
    }

    if (badges.isEmpty) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.info, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                'لا توجد ميزات',
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize - 5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return badges;
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          Icons.people_outline,
          size: AdaptiveHelper.iconSize * 2,
          color: AppColors.muted,
        ),
        SizedBox(height: AdaptiveHelper.spacing),
        const AdaptiveText(
          'لا يوجد أبناء مسجّلون بعد',
          type: AdaptiveTextType.subtitle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AdaptiveHelper.spacing / 2),
        const AdaptiveText(
          'أضف أطفالك من الشاشة الرئيسية',
          type: AdaptiveTextType.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: AdaptiveHelper.iconSize * 2,
              color: AppColors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveText(
              _error!,
              type: AdaptiveTextType.body,
              textAlign: TextAlign.center,
              color: AppColors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }
}
