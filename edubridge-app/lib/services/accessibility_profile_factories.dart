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
          switchControl: true,
          // oneHandMode: true,   ← ❌ أُزيل: كان يقص الشاشة إلى 70%
          noTimedInteractions: true,
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
    bool flag(String key) => j[key] == true || j[key] == 1 || j[key] == 'true';
    int minutes(String key, int fallback, int maximum) {
      final raw = j[key];
      final value = raw is int ? raw : int.tryParse('$raw');
      return (value ?? fallback).clamp(1, maximum).toInt();
    }
    return AccessibilityProfile(
      type: DisabilityType.values.firstWhere(
        (e) => e.name == j['type'],
        orElse: () => DisabilityType.none,
      ),
      customDisabilityName: j['customDisabilityName'] is String ? j['customDisabilityName'] as String : null,
      brainBreaksEnabled: flag('brainBreaksEnabled'),
      brainBreakIntervalMinutes: minutes('brainBreakIntervalMinutes', 15, 120),
      visualTimerEnabled: flag('visualTimerEnabled'),
      timerRenewalMinutes: minutes('timerRenewalMinutes', 5, 60),
      reducedAnimations: flag('reducedAnimations'),
      predictableTimeline: flag('predictableTimeline'),
      sensoryCalmMode: flag('sensoryCalmMode'),
      extraLargeTouchTargets: flag('extraLargeTouchTargets'),
      autoReadOnTap: flag('autoReadOnTap'),
      simpleIconsGrid: flag('simpleIconsGrid'),
      highContrast: flag('highContrast'),
      gestureNavigationEnabled: flag('gestureNavigationEnabled'),
      visualAlertsEnabled: flag('visualAlertsEnabled'),
      slowSpeech: flag('slowSpeech'),
      rhythmReading: flag('rhythmReading'),
      stepByStepLessons: flag('stepByStepLessons'),
      realLifeLinking: flag('realLifeLinking'),
      colorSymbols: flag('colorSymbols'),
      colorPatterns: flag('colorPatterns'),
      colorFiltersEnabled: flag('colorFiltersEnabled'),
      noFlashing: flag('noFlashing'),
      calmColors: flag('calmColors'),
      emergencyButton: flag('emergencyButton'),
      noTimers: flag('noTimers'),
      speechExercises: flag('speechExercises'),
      screenReaderOptimized: flag('screenReaderOptimized'),
      detailedAltText: flag('detailedAltText'),
      audioDescriptions: flag('audioDescriptions'),
      keyboardShortcuts: flag('keyboardShortcuts'),
      textOnlyMode: flag('textOnlyMode'),
      largeMouseCursor: flag('largeMouseCursor'),
      videoCaptions: flag('videoCaptions'),
      soundDescriptions: flag('soundDescriptions'),
      signLanguageTranslation: flag('signLanguageTranslation'),
      visualNotifications: flag('visualNotifications'),
      flashAlerts: flag('flashAlerts'),
      vibrationAlerts: flag('vibrationAlerts'),
      voiceToText: flag('voiceToText'),
      wordPrediction: flag('wordPrediction'),
      pictureCommunication: flag('pictureCommunication'),
      shortSentences: flag('shortSentences'),
      unlimitedTime: flag('unlimitedTime'),
      keyboardOnlyNavigation: flag('keyboardOnlyNavigation'),
      voiceControl: flag('voiceControl'),
      eyeTrackingOptimized: flag('eyeTrackingOptimized'),
      switchControl: flag('switchControl'),
      noTimedInteractions: flag('noTimedInteractions'),
      iconOnlyMode: flag('iconOnlyMode'),
      verySimpleLanguage: flag('verySimpleLanguage'),
      repetitionMode: flag('repetitionMode'),
      rewardSystem: flag('rewardSystem'),
      routineStructure: flag('routineStructure'),
      maxOptionsCount3: flag('maxOptionsCount3'),
    );
  
}
