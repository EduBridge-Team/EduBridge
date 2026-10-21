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
                  AdaptiveText(
                    context.l10n.overviewCustomize,
                    type: AdaptiveTextType.body,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: AdaptiveHelper.spacing / 4),
                  AdaptiveText(
                    context.l10n.overviewDescription,
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
        ? (profile.customDisabilityName ?? context.l10n.overviewCustom)
        : switch (profile.type) {
          DisabilityType.none => context.l10n.overviewDisabilityNone,
          DisabilityType.adhd => context.l10n.overviewDisabilityAdhd,
          DisabilityType.autismMild => context.l10n.overviewDisabilityAutismMild,
          DisabilityType.autismSevere => context.l10n.overviewDisabilityAutismSevere,
          DisabilityType.downSyndrome => context.l10n.overviewDisabilityDownSyndrome,
          DisabilityType.blind => context.l10n.overviewDisabilityBlind,
          DisabilityType.deaf => context.l10n.overviewDisabilityDeaf,
          DisabilityType.stuttering => context.l10n.overviewDisabilityStuttering,
          DisabilityType.speechDisorders => context.l10n.overviewDisabilitySpeechDisorders,
          DisabilityType.mildIntellectual => context.l10n.overviewDisabilityMildIntellectual,
          DisabilityType.colorBlindness => context.l10n.overviewDisabilityColorBlindness,
          DisabilityType.epilepsy => context.l10n.overviewDisabilityEpilepsy,
          DisabilityType.motorDisability => context.l10n.overviewDisabilityMotorDisability,
          DisabilityType.multipleDisabilities => context.l10n.overviewDisabilityMultipleDisabilities,
          DisabilityType.other => context.l10n.overviewDisabilityOther,
        };

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
                    PresentationText.initial(name, fallback: '؟'),
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
                        context.l10n.overviewAge(age.toString()),
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
                          context.l10n.disabilityType,
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
                    context.l10n.overviewActive(activeFeatures),
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
              label: context.l10n.overviewCustomizeAction,
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

    if (p.videoCaptions) addBadge(AppIcons.captions, context.l10n.overviewBadgeCaptions, AppColors.pink);
    if (p.signLanguageTranslation) {
      addBadge(AppIcons.signLanguage, context.l10n.overviewBadgeSigns, AppColors.pink);
    }
    if (p.vibrationAlerts) addBadge(Icons.vibration, context.l10n.overviewBadgeVibration, AppColors.pink);
    if (p.detailedAltText) {
      addBadge(AppIcons.volumeUp, context.l10n.overviewBadgeAudioDescription, AppColors.brandBlue);
    }
    if (p.audioDescriptions) {
      addBadge(AppIcons.speech, context.l10n.overviewBadgeVideoDescription, AppColors.brandBlue);
    }
    if (p.voiceToText) addBadge(AppIcons.mic, context.l10n.overviewBadgeDictation, AppColors.purple);
    if (p.slowSpeech) addBadge(Icons.speed, context.l10n.overviewBadgeSlowSpeech, AppColors.orangeDeep);
    if (p.voiceControl) {
      addBadge(AppIcons.mic, context.l10n.overviewBadgeVoiceControl, AppColors.brandBlue);
    }
    if (p.keyboardOnlyNavigation || p.keyboardShortcuts) {
      addBadge(Icons.keyboard, context.l10n.overviewBadgeKeyboard, AppColors.brandBlue);
    }
    if (p.verySimpleLanguage) {
      addBadge(AppIcons.info, context.l10n.overviewBadgeSimpleLanguage, AppColors.purple);
    }
    if (p.iconOnlyMode) addBadge(AppIcons.aac, context.l10n.overviewBadgeIcons, AppColors.purple);
    if (p.rewardSystem) {
      addBadge(AppIcons.starFilled, context.l10n.overviewBadgeRewards, AppColors.yellow);
    }
    if (p.shortSentences) {
      addBadge(Icons.short_text, context.l10n.overviewBadgeShortSentences, AppColors.purple);
    }
    if (p.extraLargeTouchTargets) {
      addBadge(Icons.touch_app, context.l10n.overviewBadgeLargeButtons, AppColors.brandBlue);
    }
    if (p.autoReadOnTap) {
      addBadge(AppIcons.volumeUp, context.l10n.overviewBadgeTapSpeech, AppColors.brandTeal);
    }
    if (p.highContrast) addBadge(AppIcons.theme, context.l10n.overviewBadgeContrast, AppColors.brandBlue);
    if (p.noTimers) addBadge(Icons.pause, context.l10n.overviewBadgeUntimed, AppColors.green);
    if (p.reducedAnimations) {
      addBadge(Icons.slow_motion_video, context.l10n.overviewBadgeCalmMotion, AppColors.brandTeal);
    }
    if (p.emergencyButton) {
      addBadge(AppIcons.emergency, context.l10n.overviewBadgeEmergency, AppColors.red);
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
                context.l10n.overviewNoFeatures,
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
        AdaptiveText(
          context.l10n.overviewNoChildren,
          type: AdaptiveTextType.subtitle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AdaptiveHelper.spacing / 2),
        AdaptiveText(
          context.l10n.overviewAddChildren,
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
              _error == 1 ? context.l10n.overviewSpecialistOnly : _error == 2 ? context.l10n.overviewLoadFailed : context.l10n.overviewConnectionFailed,
              type: AdaptiveTextType.body,
              textAlign: TextAlign.center,
              color: AppColors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: context.l10n.overviewRetry,
              icon: AppIcons.refresh,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }
}
