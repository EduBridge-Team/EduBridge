part of 'child_accessibility_settings_screen.dart';

extension _ChildAccessibilitySettingsScreenStateView on _ChildAccessibilitySettingsScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return AdaptiveWrapper(
      screenTitle: context.l10n.adaptationSettingsFor(widget.childName),
      child: Scaffold(
        appBar: buildChildSettingsAppBar(context, widget.childName),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F9FC),
        body: ValueListenableBuilder<AccessibilityProfile>(
          valueListenable: AccessibilityService.instance.profile,
          builder: (context, _, __) {
            final p = _p;
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                buildInfoBanner(context, c, widget.childName),
                if (!_canEdit)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(context.l10n.adaptationReadOnly),
                  ),
                const SizedBox(height: 12),
                buildDisabilitySelector(
                  context: context,
                  c: c,
                  selectedValue: _selectedDisability,
                  onTap: _canChange ? _openDisabilityPicker : null,
                ),
                if (_canEdit && _selectedDisability == 'أخرى') ...[
                  const SizedBox(height: 12),
                  buildCustomDisabilityBox(
                    context: context,
                    c: c,
                    controller: _customNameCtrl,
                    onSave: _applyCustom,
                  ),
                ],
                const SizedBox(height: 12),

                buildFeatureSection(
                  title: context.l10n.adaptationVisualSection,
                  initiallyExpanded: true,
                  icon: AppIcons.blind,
                  color: AppColors.brandBlue,
                  c: c,
                  children: [
                    sw(context.l10n.adaptationScreenReader, context.l10n.adaptationScreenReaderHint,
                        p.screenReaderOptimized,
                        (v) => _set(p.copyWith(screenReaderOptimized: v)), enabled: _canChange),
                    sw(context.l10n.adaptationDetailedImages, context.l10n.adaptationDetailedImagesHint,
                        p.detailedAltText,
                        (v) => _set(p.copyWith(detailedAltText: v)), enabled: _canChange),
                    sw(context.l10n.adaptationAudioDescriptions, context.l10n.adaptationAudioDescriptionsHint,
                        p.audioDescriptions,
                        (v) => _set(p.copyWith(audioDescriptions: v)), enabled: _canChange),
                    sw(context.l10n.adaptationKeyboardShortcuts, context.l10n.adaptationKeyboardShortcutsHint,
                        p.keyboardShortcuts,
                        (v) => _set(p.copyWith(keyboardShortcuts: v)), enabled: _canChange),
                    sw(context.l10n.adaptationTextOnly, context.l10n.adaptationTextOnlyHint,
                        p.textOnlyMode, (v) => _set(p.copyWith(textOnlyMode: v)), enabled: _canChange),
                    sw(context.l10n.adaptationLargeCursor, context.l10n.adaptationLargeCursorHint,
                        p.largeMouseCursor,
                        (v) => _set(p.copyWith(largeMouseCursor: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: context.l10n.adaptationHearingSection,
                  initiallyExpanded: false,
                  icon: AppIcons.deaf,
                  color: AppColors.pink,
                  c: c,
                  children: [
                    sw(context.l10n.adaptationCaptions, context.l10n.adaptationCaptionsHint,
                        p.videoCaptions,
                        (v) => _set(p.copyWith(videoCaptions: v)), enabled: _canChange),
                    sw(context.l10n.adaptationSoundDescriptions, context.l10n.adaptationSoundDescriptionsHint,
                        p.soundDescriptions, (v) => _set(p.copyWith(soundDescriptions: v)), enabled: _canChange),
                    sw(context.l10n.adaptationSignLanguage, context.l10n.adaptationSignLanguageHint,
                        p.signLanguageTranslation,
                        (v) => _set(p.copyWith(signLanguageTranslation: v)), enabled: _canChange),
                    sw(context.l10n.adaptationVisualNotifications, context.l10n.adaptationVisualNotificationsHint,
                        p.visualNotifications, (v) => _set(p.copyWith(visualNotifications: v)), enabled: _canChange),
                    sw(context.l10n.adaptationFlashAlerts, context.l10n.adaptationFlashAlertsHint,
                        p.flashAlerts, (_) {}, enabled: false),
                    sw(context.l10n.adaptationVibration, context.l10n.adaptationVibrationHint, p.vibrationAlerts,
                        (v) => _set(p.copyWith(vibrationAlerts: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: context.l10n.adaptationMotorSection,
                  initiallyExpanded: false,
                  icon: AppIcons.motor,
                  color: AppColors.brandBlue,
                  c: c,
                  children: [
                    sw(context.l10n.adaptationKeyboardNavigation, context.l10n.adaptationKeyboardNavigationHint,
                        p.keyboardOnlyNavigation,
                        (v) => _set(p.copyWith(keyboardOnlyNavigation: v)), enabled: _canChange),
                    sw(context.l10n.adaptationVoiceControl, context.l10n.adaptationVoiceControlHint,
                        p.voiceControl, (_) {}, enabled: false),
                    sw(context.l10n.adaptationEyeTracking, context.l10n.adaptationUnavailable,
                        false, (_) {}, enabled: false),
                    sw(context.l10n.adaptationSwitchControl, context.l10n.adaptationSwitchControlHint,
                        p.switchControl,
                        (v) => _set(p.copyWith(switchControl: v)), enabled: _canChange),
                    sw(context.l10n.adaptationNoTimedInteractions, context.l10n.adaptationNoTimedInteractionsHint,
                        p.noTimedInteractions,
                        (v) => _set(p.copyWith(noTimedInteractions: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: context.l10n.adaptationCognitiveSection,
                  initiallyExpanded: false,
                  icon: AppIcons.cognitive,
                  color: AppColors.purple,
                  c: c,
                  children: [
                    sw(context.l10n.adaptationStepByStep, context.l10n.adaptationStepByStepHint,
                        p.stepByStepLessons,
                        (v) => _set(p.copyWith(stepByStepLessons: v)), enabled: _canChange),
                    sw(context.l10n.adaptationSimpleGrid, context.l10n.adaptationSimpleGridHint,
                        p.simpleIconsGrid,
                        (v) => _set(p.copyWith(simpleIconsGrid: v)), enabled: _canChange),
                    sw(context.l10n.adaptationIconButtons, context.l10n.adaptationIconButtonsHint,
                        p.iconOnlyMode, (v) => _set(p.copyWith(iconOnlyMode: v)), enabled: _canChange),
                    sw(context.l10n.adaptationSimpleLanguage, context.l10n.adaptationSimpleLanguageHint,
                        p.verySimpleLanguage,
                        (v) => _set(p.copyWith(verySimpleLanguage: v)), enabled: _canChange),
                    sw(context.l10n.adaptationReadScreenTitle, context.l10n.adaptationReadScreenTitleHint,
                        p.repetitionMode,
                        (v) => _set(p.copyWith(repetitionMode: v)), enabled: _canChange),
                    sw(context.l10n.adaptationStarRewards, context.l10n.adaptationStarRewardsHint, p.rewardSystem,
                        (v) => _set(p.copyWith(rewardSystem: v)), enabled: _canChange),
                    sw(context.l10n.adaptationRoutine, context.l10n.adaptationRoutineHint,
                        p.routineStructure, (v) => _set(p.copyWith(routineStructure: v)), enabled: _canChange),
                    sw(context.l10n.adaptationThreeChoices, context.l10n.adaptationThreeChoicesHint,
                        p.maxOptionsCount3,
                        (v) => _set(p.copyWith(maxOptionsCount3: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: context.l10n.adaptationSpeechSection,
                  initiallyExpanded: false,
                  icon: AppIcons.speech,
                  color: AppColors.orangeDeep,
                  c: c,
                  children: [
                    sw(context.l10n.adaptationSpeechToText, context.l10n.adaptationSpeechToTextHint,
                        p.voiceToText,
                        (v) => _set(p.copyWith(voiceToText: v)), enabled: _canChange),
                    sw(context.l10n.adaptationWordPrediction, context.l10n.adaptationWordPredictionHint,
                        p.wordPrediction,
                        (v) => _set(p.copyWith(wordPrediction: v)), enabled: _canChange),
                    sw(context.l10n.adaptationShortSentences, context.l10n.adaptationShortSentencesHint,
                        p.shortSentences,
                        (v) => _set(p.copyWith(shortSentences: v)), enabled: _canChange),
                    sw(context.l10n.adaptationUnlimitedTime, context.l10n.adaptationUnlimitedTimeHint,
                        p.unlimitedTime,
                        (v) => _set(p.copyWith(unlimitedTime: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: context.l10n.adaptationGeneralSection,
                  initiallyExpanded: true,
                  icon: AppIcons.settings,
                  color: AppColors.muted,
                  c: c,
                  children: [
                    sw(context.l10n.adaptationExtraLargeTargets, context.l10n.adaptationExtraLargeTargetsHint,
                        p.extraLargeTouchTargets,
                        (v) => _set(p.copyWith(extraLargeTouchTargets: v)), enabled: _canChange),
                    sw(context.l10n.adaptationReducedMotion, context.l10n.adaptationReducedMotionHint, p.reducedAnimations,
                        (v) => _set(p.copyWith(reducedAnimations: v)), enabled: _canChange),
                    sw(context.l10n.adaptationNoFlashing, context.l10n.adaptationNoFlashingHint,
                        p.noFlashing,
                        (v) => _set(p.copyWith(noFlashing: v)), enabled: _canChange),
                    sw(context.l10n.adaptationAutoRead, context.l10n.adaptationAutoReadHint,
                        p.autoReadOnTap,
                        (v) => _set(p.copyWith(autoReadOnTap: v)), enabled: _canChange),
                    sw(context.l10n.adaptationSlowSpeech, context.l10n.adaptationSlowSpeechHint, p.slowSpeech,
                        (v) => _set(p.copyWith(slowSpeech: v)), enabled: _canChange),
                    sw(context.l10n.adaptationStrongBorders, context.l10n.adaptationStrongBordersHint,
                        p.highContrast, (v) => _set(p.copyWith(highContrast: v)), enabled: _canChange),
                    sw(context.l10n.adaptationColorFilters, context.l10n.adaptationColorFiltersHint,
                        p.colorFiltersEnabled,
                        (v) => _set(p.copyWith(colorFiltersEnabled: v)), enabled: _canChange),
                    sw(context.l10n.adaptationSensoryCalm, context.l10n.adaptationSensoryCalmHint,
                        p.sensoryCalmMode,
                        (v) => _set(p.copyWith(sensoryCalmMode: v)), enabled: _canChange),
                    sw(context.l10n.adaptationEmergency, context.l10n.adaptationEmergencyHint, p.emergencyButton,
                        (v) => _set(p.copyWith(emergencyButton: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: context.l10n.adaptationBreakSection,
                  initiallyExpanded: false,
                  icon: Icons.pause_circle_outline,
                  color: AppColors.teal,
                  c: c,
                  children: [
                    sw(context.l10n.adaptationBrainBreaks, context.l10n.adaptationBrainBreaksHint,
                        p.brainBreaksEnabled,
                        (v) => _set(p.copyWith(brainBreaksEnabled: v)), enabled: _canChange),
                    buildDurationSetting(
                      title: context.l10n.adaptationBreakInterval,
                      subtitle: context.l10n.adaptationBreakIntervalHint,
                      value: p.brainBreakIntervalMinutes,
                      choices: const [5, 10, 15, 20, 30, 45, 60, 90, 120],
                      unit: context.l10n.adaptationMinute,
                      optionLabel: context.l10n.adaptationMinutes,
                      onChanged: _canChange && p.brainBreaksEnabled
                          ? (value) => _set(p.copyWith(brainBreakIntervalMinutes: value)) : null,
                    ),
                    buildDurationSetting(
                      title: context.l10n.adaptationBreakDuration,
                      subtitle: p.noTimedInteractions || p.noTimers
                          ? context.l10n.adaptationBreakHiddenHint
                          : context.l10n.adaptationBreakDurationHint,
                      value: p.brainBreakDurationSeconds,
                      choices: const [15, 30, 60, 90, 120],
                      unit: context.l10n.adaptationSecond,
                      optionLabel: context.l10n.adaptationSeconds,
                      onChanged: _canChange
                          ? (value) => _set(p.copyWith(brainBreakDurationSeconds: value)) : null,
                    ),

                    sw(context.l10n.adaptationTaskTimer, context.l10n.adaptationTaskTimerHint,
                        p.visualTimerEnabled,
                        (v) => _set(p.copyWith(visualTimerEnabled: v)), enabled: _canChange),
                    buildDurationSetting(
                      title: context.l10n.adaptationTaskDuration,
                      subtitle: p.unlimitedTime || p.noTimers || p.noTimedInteractions
                          ? context.l10n.adaptationTaskDisabledHint
                          : context.l10n.adaptationTaskDurationHint,
                      value: p.timerRenewalMinutes,
                      choices: const [1, 3, 5, 10, 15, 20, 30, 45, 60],
                      unit: context.l10n.adaptationMinute,
                      optionLabel: context.l10n.adaptationMinutes,
                      onChanged: _canChange && p.visualTimerEnabled &&
                          !p.unlimitedTime && !p.noTimers && !p.noTimedInteractions
                          ? (value) => _set(p.copyWith(timerRenewalMinutes: value)) : null,
                    ),
                    sw(context.l10n.adaptationHideTimers, context.l10n.adaptationHideTimersHint,
                        p.noTimers,
                        (v) => _set(p.copyWith(noTimers: v)), enabled: _canChange),
                  ],
                ),

                buildFeatureSection(
                  title: context.l10n.adaptationReset,
                  initiallyExpanded: false,
                  icon: AppIcons.refresh,
                  color: AppColors.brandBlue,
                  c: c,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(AppIcons.refresh),
                      label: Text(context.l10n.adaptationReset),
                      onPressed: !_canChange ? null : () async {
                        final saved = await _set(const AccessibilityProfile(type: DisabilityType.none));
                        if (saved && mounted) _refreshState(() => _selectedDisability = null);
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1769C2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: !_canChange ? null : () async {
                      final saved = await _set(_p);
                      if (saved && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.adaptationSaved)),
                        );
                      }
                    },
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 19),
                    label: Text(_saving ? context.l10n.adaptationSaving : context.l10n.adaptationSave),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
