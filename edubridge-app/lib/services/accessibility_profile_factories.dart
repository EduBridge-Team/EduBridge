part of 'accessibility_profile.dart';

AccessibilityProfile _recommendedAccessibilityProfile(
  DisabilityType type, {
  String? customName,
}) {
    switch (type) {
      case DisabilityType.adhd:
        return const AccessibilityProfile(
          type: DisabilityType.adhd,
          brainBreaksEnabled: true,
          visualTimerEnabled: true,
          brainBreakIntervalMinutes: 12,
          timerRenewalMinutes: 5,
          reducedAnimations: true,
          rewardSystem: true,
          noTimedInteractions: false,
        );

      case DisabilityType.autismMild:
        return const AccessibilityProfile(
          type: DisabilityType.autismMild,
          predictableTimeline: true,
          reducedAnimations: true,
          timerRenewalMinutes: 10,
          routineStructure: true,
          iconOnlyMode: false,
          maxOptionsCount3: true,
        );

      case DisabilityType.autismSevere:
        return const AccessibilityProfile(
          type: DisabilityType.autismSevere,
          predictableTimeline: true,
          reducedAnimations: true,
          sensoryCalmMode: true,
          timerRenewalMinutes: 10,
          routineStructure: true,
          iconOnlyMode: true,
          maxOptionsCount3: true,
          verySimpleLanguage: true,
        );

      case DisabilityType.downSyndrome:
        return const AccessibilityProfile(
          type: DisabilityType.downSyndrome,
          extraLargeTouchTargets: true,
          autoReadOnTap: true,
          simpleIconsGrid: true,
          reducedAnimations: true,
          slowSpeech: true,
          noTimers: true,
          timerRenewalMinutes: 3,
          verySimpleLanguage: true,
          repetitionMode: true,
          rewardSystem: true,
          routineStructure: true,
          maxOptionsCount3: true,
          pictureCommunication: true,
          unlimitedTime: true,
          videoCaptions: true,
          detailedAltText: true,
        );

      case DisabilityType.blind:
        return const AccessibilityProfile(
          type: DisabilityType.blind,
          highContrast: true,
          gestureNavigationEnabled: true,
          autoReadOnTap: true,
          visualTimerEnabled: true,
          timerRenewalMinutes: 5,
          noFlashing: true,
          screenReaderOptimized: true,
          detailedAltText: true,
          audioDescriptions: true,
          keyboardShortcuts: true,
          textOnlyMode: true,
          largeMouseCursor: true,
          keyboardOnlyNavigation: true,
        );

      case DisabilityType.deaf:
        return const AccessibilityProfile(
          type: DisabilityType.deaf,
          visualAlertsEnabled: true,
          timerRenewalMinutes: 5,
          videoCaptions: true,
          soundDescriptions: true,
          signLanguageTranslation: true,
          visualNotifications: true,
          flashAlerts: true,
          vibrationAlerts: true,
        );

      case DisabilityType.stuttering:
        return const AccessibilityProfile(
          type: DisabilityType.stuttering,
          slowSpeech: true,
          rhythmReading: true,
          noTimers: true,
          reducedAnimations: true,
          autoReadOnTap: true,
          timerRenewalMinutes: 5,
          voiceToText: true,
          pictureCommunication: true,
          shortSentences: true,
          unlimitedTime: true,
          noTimedInteractions: true,
        );

      case DisabilityType.speechDisorders:
        return const AccessibilityProfile(
          type: DisabilityType.speechDisorders,
          speechExercises: true,
          slowSpeech: true,
          noTimers: true,
          autoReadOnTap: true,
          timerRenewalMinutes: 5,
          voiceToText: true,
          wordPrediction: true,
          pictureCommunication: true,
          shortSentences: true,
          unlimitedTime: true,
        );

      case DisabilityType.mildIntellectual:
        return const AccessibilityProfile(
          type: DisabilityType.mildIntellectual,
          stepByStepLessons: true,
          realLifeLinking: true,
          extraLargeTouchTargets: true,
          autoReadOnTap: true,
          slowSpeech: true,
          noTimers: true,
          reducedAnimations: true,
          timerRenewalMinutes: 3,
          verySimpleLanguage: true,
          shortSentences: true,
          rewardSystem: true,
          routineStructure: true,
          repetitionMode: true,
          maxOptionsCount3: true,
          pictureCommunication: true,
        );

      case DisabilityType.colorBlindness:
        return const AccessibilityProfile(
          type: DisabilityType.colorBlindness,
          colorSymbols: true,
          colorPatterns: true,
          colorFiltersEnabled: true,
          timerRenewalMinutes: 5,
          detailedAltText: true,
        );

      case DisabilityType.epilepsy:
        return const AccessibilityProfile(
          type: DisabilityType.epilepsy,
          noFlashing: true,
          calmColors: true,
          reducedAnimations: true,
          emergencyButton: true,
          sensoryCalmMode: true,
          noTimers: true,
          timerRenewalMinutes: 5,
        );

      // ═══════════════════════════════════════
      // ✅ إصلاح: أُزيل oneHandMode من البروفايل الافتراضي
      //    لأنه كان يقص الشاشة إلى 70% ويعطّل الـ AppBar.
      //    من يحتاج وضع اليد الواحدة يمكنه تفعيله يدوياً.
      // ═══════════════════════════════════════
      case DisabilityType.motorDisability:
        return const AccessibilityProfile(
          type: DisabilityType.motorDisability,
          extraLargeTouchTargets: true,
          reducedAnimations: true,
          noTimers: true,
          timerRenewalMinutes: 5,
          keyboardOnlyNavigation: true,
          keyboardShortcuts: true,
          voiceControl: true,
          eyeTrackingOptimized: true,
          switchControl: true,
          // oneHandMode: true,   ← ❌ أُزيل: كان يقص الشاشة إلى 70%
          noTimedInteractions: true,
          largeMouseCursor: true,
        );

      case DisabilityType.multipleDisabilities:
        return const AccessibilityProfile(
          type: DisabilityType.multipleDisabilities,
          extraLargeTouchTargets: true,
          autoReadOnTap: true,
          slowSpeech: true,
          noTimers: true,
          reducedAnimations: true,
          highContrast: true,
          visualAlertsEnabled: true,
          screenReaderOptimized: true,
          detailedAltText: true,
          videoCaptions: true,
          signLanguageTranslation: true,
          verySimpleLanguage: true,
          pictureCommunication: true,
          keyboardOnlyNavigation: true,
          voiceControl: true,
          rewardSystem: true,
          maxOptionsCount3: true,
        );

      case DisabilityType.other:
        return AccessibilityProfile(
          type: DisabilityType.other,
          customDisabilityName: customName,
          reducedAnimations: true,
          extraLargeTouchTargets: true,
          autoReadOnTap: true,
          timerRenewalMinutes: 5,
        );

      case DisabilityType.none:
        return const AccessibilityProfile(type: DisabilityType.none);
    }
  
}

AccessibilityProfile _accessibilityProfileFromJson(Map<String, dynamic> j) {
    return AccessibilityProfile(
      type: DisabilityType.values.firstWhere(
        (e) => e.name == j['type'],
        orElse: () => DisabilityType.none,
      ),
      customDisabilityName: j['customDisabilityName'],
      brainBreaksEnabled: j['brainBreaksEnabled'] ?? false,
      brainBreakIntervalMinutes: j['brainBreakIntervalMinutes'] ?? 15,
      visualTimerEnabled: j['visualTimerEnabled'] ?? false,
      timerRenewalMinutes: j['timerRenewalMinutes'] ?? 5,
      reducedAnimations: j['reducedAnimations'] ?? false,
      predictableTimeline: j['predictableTimeline'] ?? false,
      sensoryCalmMode: j['sensoryCalmMode'] ?? false,
      extraLargeTouchTargets: j['extraLargeTouchTargets'] ?? false,
      autoReadOnTap: j['autoReadOnTap'] ?? false,
      simpleIconsGrid: j['simpleIconsGrid'] ?? false,
      highContrast: j['highContrast'] ?? false,
      gestureNavigationEnabled: j['gestureNavigationEnabled'] ?? false,
      visualAlertsEnabled: j['visualAlertsEnabled'] ?? false,
      slowSpeech: j['slowSpeech'] ?? false,
      rhythmReading: j['rhythmReading'] ?? false,
      stepByStepLessons: j['stepByStepLessons'] ?? false,
      realLifeLinking: j['realLifeLinking'] ?? false,
      colorSymbols: j['colorSymbols'] ?? false,
      colorPatterns: j['colorPatterns'] ?? false,
      colorFiltersEnabled: j['colorFiltersEnabled'] ?? false,
      noFlashing: j['noFlashing'] ?? false,
      calmColors: j['calmColors'] ?? false,
      emergencyButton: j['emergencyButton'] ?? false,
      noTimers: j['noTimers'] ?? false,
      speechExercises: j['speechExercises'] ?? false,
      screenReaderOptimized: j['screenReaderOptimized'] ?? false,
      detailedAltText: j['detailedAltText'] ?? false,
      audioDescriptions: j['audioDescriptions'] ?? false,
      keyboardShortcuts: j['keyboardShortcuts'] ?? false,
      textOnlyMode: j['textOnlyMode'] ?? false,
      largeMouseCursor: j['largeMouseCursor'] ?? false,
      videoCaptions: j['videoCaptions'] ?? false,
      soundDescriptions: j['soundDescriptions'] ?? false,
      signLanguageTranslation: j['signLanguageTranslation'] ?? false,
      visualNotifications: j['visualNotifications'] ?? false,
      flashAlerts: j['flashAlerts'] ?? false,
      vibrationAlerts: j['vibrationAlerts'] ?? false,
      voiceToText: j['voiceToText'] ?? false,
      wordPrediction: j['wordPrediction'] ?? false,
      pictureCommunication: j['pictureCommunication'] ?? false,
      shortSentences: j['shortSentences'] ?? false,
      unlimitedTime: j['unlimitedTime'] ?? false,
      keyboardOnlyNavigation: j['keyboardOnlyNavigation'] ?? false,
      voiceControl: j['voiceControl'] ?? false,
      eyeTrackingOptimized: j['eyeTrackingOptimized'] ?? false,
      switchControl: j['switchControl'] ?? false,
      noTimedInteractions: j['noTimedInteractions'] ?? false,
      iconOnlyMode: j['iconOnlyMode'] ?? false,
      verySimpleLanguage: j['verySimpleLanguage'] ?? false,
      repetitionMode: j['repetitionMode'] ?? false,
      rewardSystem: j['rewardSystem'] ?? false,
      routineStructure: j['routineStructure'] ?? false,
      maxOptionsCount3: j['maxOptionsCount3'] ?? false,
    );
  
}
