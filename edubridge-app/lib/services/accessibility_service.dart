// خدمة التكييف الديناميكي — تدعم بروفايل منفصل لكل طفل + ميزات كل الإعاقات
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// أنواع الإعاقات المدعومة
enum DisabilityType {
  none,
  adhd,
  autismMild,
  autismSevere,
  downSyndrome,
  blind,
  deaf,
  stuttering,
  speechDisorders,
  mildIntellectual,
  colorBlindness,
  epilepsy,
  motorDisability,        // إعاقات حركية
  multipleDisabilities,   // إعاقات متعددة
  other,
}

/// بروفايل التكييف لكل طفل
class AccessibilityProfile {
  final DisabilityType type;
  final String? customDisabilityName;

  // ═══════════════════════════════════════════════════════════
  //  ─── الميزات العامة ───
  // ═══════════════════════════════════════════════════════════
  final bool brainBreaksEnabled;
  final int brainBreakIntervalMinutes;
  final bool visualTimerEnabled;
  final int timerRenewalMinutes;
  final bool reducedAnimations;
  final bool predictableTimeline;
  final bool sensoryCalmMode;
  final bool extraLargeTouchTargets;
  final bool autoReadOnTap;
  final bool simpleIconsGrid;
  final bool highContrast;
  final bool gestureNavigationEnabled;
  final bool visualAlertsEnabled;
  final bool slowSpeech;
  final bool rhythmReading;
  final bool stepByStepLessons;
  final bool realLifeLinking;
  final bool colorSymbols;
  final bool colorPatterns;
  final bool colorFiltersEnabled;
  final bool noFlashing;
  final bool calmColors;
  final bool emergencyButton;
  final bool noTimers;
  final bool speechExercises;

  // ═══════════════════════════════════════════════════════════
  //  ميزات الإعاقات البصرية
  // ═══════════════════════════════════════════════════════════
  final bool screenReaderOptimized;
  final bool detailedAltText;
  final bool audioDescriptions;
  final bool keyboardShortcuts;
  final bool textOnlyMode;
  final bool largeMouseCursor;

  // ═══════════════════════════════════════════════════════════
  //  ميزات الإعاقات السمعية
  // ═══════════════════════════════════════════════════════════
  final bool videoCaptions;
  final bool soundDescriptions;
  final bool signLanguageTranslation;
  final bool visualNotifications;
  final bool flashAlerts;
  final bool vibrationAlerts;

  // ═══════════════════════════════════════════════════════════
  //  ميزات اضطرابات النطق
  // ═══════════════════════════════════════════════════════════
  final bool voiceToText;
  final bool wordPrediction;
  final bool pictureCommunication;
  final bool shortSentences;
  final bool unlimitedTime;

  // ═══════════════════════════════════════════════════════════
  //  ميزات الإعاقات الحركية
  // ═══════════════════════════════════════════════════════════
  final bool keyboardOnlyNavigation;
  final bool voiceControl;
  final bool eyeTrackingOptimized;
  final bool switchControl;
  final bool noTimedInteractions;

  // ═══════════════════════════════════════════════════════════
  //  ميزات الإعاقات الذهنية
  // ═══════════════════════════════════════════════════════════
  final bool iconOnlyMode;
  final bool verySimpleLanguage;
  final bool repetitionMode;
  final bool rewardSystem;
  final bool routineStructure;
  final bool maxOptionsCount3;

  const AccessibilityProfile({
    required this.type,
    this.customDisabilityName,
    this.brainBreaksEnabled = false,
    this.brainBreakIntervalMinutes = 15,
    this.visualTimerEnabled = false,
    this.timerRenewalMinutes = 5,
    this.reducedAnimations = false,
    this.predictableTimeline = false,
    this.sensoryCalmMode = false,
    this.extraLargeTouchTargets = false,
    this.autoReadOnTap = false,
    this.simpleIconsGrid = false,
    this.highContrast = false,
    this.gestureNavigationEnabled = false,
    this.visualAlertsEnabled = false,
    this.slowSpeech = false,
    this.rhythmReading = false,
    this.stepByStepLessons = false,
    this.realLifeLinking = false,
    this.colorSymbols = false,
    this.colorPatterns = false,
    this.colorFiltersEnabled = false,
    this.noFlashing = false,
    this.calmColors = false,
    this.emergencyButton = false,
    this.noTimers = false,
    this.speechExercises = false,
    this.screenReaderOptimized = false,
    this.detailedAltText = false,
    this.audioDescriptions = false,
    this.keyboardShortcuts = false,
    this.textOnlyMode = false,
    this.largeMouseCursor = false,
    this.videoCaptions = false,
    this.soundDescriptions = false,
    this.signLanguageTranslation = false,
    this.visualNotifications = false,
    this.flashAlerts = false,
    this.vibrationAlerts = false,
    this.voiceToText = false,
    this.wordPrediction = false,
    this.pictureCommunication = false,
    this.shortSentences = false,
    this.unlimitedTime = false,
    this.keyboardOnlyNavigation = false,
    this.voiceControl = false,
    this.eyeTrackingOptimized = false,
    this.switchControl = false,
    this.noTimedInteractions = false,
    this.iconOnlyMode = false,
    this.verySimpleLanguage = false,
    this.repetitionMode = false,
    this.rewardSystem = false,
    this.routineStructure = false,
    this.maxOptionsCount3 = false,
  });

  AccessibilityProfile copyWith({
    DisabilityType? type,
    String? customDisabilityName,
    bool? brainBreaksEnabled,
    int? brainBreakIntervalMinutes,
    bool? visualTimerEnabled,
    int? timerRenewalMinutes,
    bool? reducedAnimations,
    bool? predictableTimeline,
    bool? sensoryCalmMode,
    bool? extraLargeTouchTargets,
    bool? autoReadOnTap,
    bool? simpleIconsGrid,
    bool? highContrast,
    bool? gestureNavigationEnabled,
    bool? visualAlertsEnabled,
    bool? slowSpeech,
    bool? rhythmReading,
    bool? stepByStepLessons,
    bool? realLifeLinking,
    bool? colorSymbols,
    bool? colorPatterns,
    bool? colorFiltersEnabled,
    bool? noFlashing,
    bool? calmColors,
    bool? emergencyButton,
    bool? noTimers,
    bool? speechExercises,
    bool? screenReaderOptimized,
    bool? detailedAltText,
    bool? audioDescriptions,
    bool? keyboardShortcuts,
    bool? textOnlyMode,
    bool? largeMouseCursor,
    bool? videoCaptions,
    bool? soundDescriptions,
    bool? signLanguageTranslation,
    bool? visualNotifications,
    bool? flashAlerts,
    bool? vibrationAlerts,
    bool? voiceToText,
    bool? wordPrediction,
    bool? pictureCommunication,
    bool? shortSentences,
    bool? unlimitedTime,
    bool? keyboardOnlyNavigation,
    bool? voiceControl,
    bool? eyeTrackingOptimized,
    bool? switchControl,
    bool? oneHandMode,
    bool? noTimedInteractions,
    bool? iconOnlyMode,
    bool? verySimpleLanguage,
    bool? repetitionMode,
    bool? rewardSystem,
    bool? routineStructure,
    bool? maxOptionsCount3,
  }) {
    return AccessibilityProfile(
      type: type ?? this.type,
      customDisabilityName: customDisabilityName ?? this.customDisabilityName,
      brainBreaksEnabled: brainBreaksEnabled ?? this.brainBreaksEnabled,
      brainBreakIntervalMinutes:
          brainBreakIntervalMinutes ?? this.brainBreakIntervalMinutes,
      visualTimerEnabled: visualTimerEnabled ?? this.visualTimerEnabled,
      timerRenewalMinutes: timerRenewalMinutes ?? this.timerRenewalMinutes,
      reducedAnimations: reducedAnimations ?? this.reducedAnimations,
      predictableTimeline: predictableTimeline ?? this.predictableTimeline,
      sensoryCalmMode: sensoryCalmMode ?? this.sensoryCalmMode,
      extraLargeTouchTargets:
          extraLargeTouchTargets ?? this.extraLargeTouchTargets,
      autoReadOnTap: autoReadOnTap ?? this.autoReadOnTap,
      simpleIconsGrid: simpleIconsGrid ?? this.simpleIconsGrid,
      highContrast: highContrast ?? this.highContrast,
      gestureNavigationEnabled:
          gestureNavigationEnabled ?? this.gestureNavigationEnabled,
      visualAlertsEnabled: visualAlertsEnabled ?? this.visualAlertsEnabled,
      slowSpeech: slowSpeech ?? this.slowSpeech,
      rhythmReading: rhythmReading ?? this.rhythmReading,
      stepByStepLessons: stepByStepLessons ?? this.stepByStepLessons,
      realLifeLinking: realLifeLinking ?? this.realLifeLinking,
      colorSymbols: colorSymbols ?? this.colorSymbols,
      colorPatterns: colorPatterns ?? this.colorPatterns,
      colorFiltersEnabled: colorFiltersEnabled ?? this.colorFiltersEnabled,
      noFlashing: noFlashing ?? this.noFlashing,
      calmColors: calmColors ?? this.calmColors,
      emergencyButton: emergencyButton ?? this.emergencyButton,
      noTimers: noTimers ?? this.noTimers,
      speechExercises: speechExercises ?? this.speechExercises,
      screenReaderOptimized:
          screenReaderOptimized ?? this.screenReaderOptimized,
      detailedAltText: detailedAltText ?? this.detailedAltText,
      audioDescriptions: audioDescriptions ?? this.audioDescriptions,
      keyboardShortcuts: keyboardShortcuts ?? this.keyboardShortcuts,
      textOnlyMode: textOnlyMode ?? this.textOnlyMode,
      largeMouseCursor: largeMouseCursor ?? this.largeMouseCursor,
      videoCaptions: videoCaptions ?? this.videoCaptions,
      soundDescriptions: soundDescriptions ?? this.soundDescriptions,
      signLanguageTranslation:
          signLanguageTranslation ?? this.signLanguageTranslation,
      visualNotifications: visualNotifications ?? this.visualNotifications,
      flashAlerts: flashAlerts ?? this.flashAlerts,
      vibrationAlerts: vibrationAlerts ?? this.vibrationAlerts,
      voiceToText: voiceToText ?? this.voiceToText,
      wordPrediction: wordPrediction ?? this.wordPrediction,
      pictureCommunication:
          pictureCommunication ?? this.pictureCommunication,
      shortSentences: shortSentences ?? this.shortSentences,
      unlimitedTime: unlimitedTime ?? this.unlimitedTime,
      keyboardOnlyNavigation:
          keyboardOnlyNavigation ?? this.keyboardOnlyNavigation,
      voiceControl: voiceControl ?? this.voiceControl,
      eyeTrackingOptimized:
          eyeTrackingOptimized ?? this.eyeTrackingOptimized,
     
      iconOnlyMode: iconOnlyMode ?? this.iconOnlyMode,
      verySimpleLanguage: verySimpleLanguage ?? this.verySimpleLanguage,
      repetitionMode: repetitionMode ?? this.repetitionMode,
      rewardSystem: rewardSystem ?? this.rewardSystem,
      routineStructure: routineStructure ?? this.routineStructure,
      maxOptionsCount3: maxOptionsCount3 ?? this.maxOptionsCount3,
    );
  }

  /// البروفايل المُوصى به لكل نوع إعاقة
  factory AccessibilityProfile.recommendedFor(
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

  // ─── JSON ───
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'customDisabilityName': customDisabilityName,
        'brainBreaksEnabled': brainBreaksEnabled,
        'brainBreakIntervalMinutes': brainBreakIntervalMinutes,
        'visualTimerEnabled': visualTimerEnabled,
        'timerRenewalMinutes': timerRenewalMinutes,
        'reducedAnimations': reducedAnimations,
        'predictableTimeline': predictableTimeline,
        'sensoryCalmMode': sensoryCalmMode,
        'extraLargeTouchTargets': extraLargeTouchTargets,
        'autoReadOnTap': autoReadOnTap,
        'simpleIconsGrid': simpleIconsGrid,
        'highContrast': highContrast,
        'gestureNavigationEnabled': gestureNavigationEnabled,
        'visualAlertsEnabled': visualAlertsEnabled,
        'slowSpeech': slowSpeech,
        'rhythmReading': rhythmReading,
        'stepByStepLessons': stepByStepLessons,
        'realLifeLinking': realLifeLinking,
        'colorSymbols': colorSymbols,
        'colorPatterns': colorPatterns,
        'colorFiltersEnabled': colorFiltersEnabled,
        'noFlashing': noFlashing,
        'calmColors': calmColors,
        'emergencyButton': emergencyButton,
        'noTimers': noTimers,
        'speechExercises': speechExercises,
        'screenReaderOptimized': screenReaderOptimized,
        'detailedAltText': detailedAltText,
        'audioDescriptions': audioDescriptions,
        'keyboardShortcuts': keyboardShortcuts,
        'textOnlyMode': textOnlyMode,
        'largeMouseCursor': largeMouseCursor,
        'videoCaptions': videoCaptions,
        'soundDescriptions': soundDescriptions,
        'signLanguageTranslation': signLanguageTranslation,
        'visualNotifications': visualNotifications,
        'flashAlerts': flashAlerts,
        'vibrationAlerts': vibrationAlerts,
        'voiceToText': voiceToText,
        'wordPrediction': wordPrediction,
        'pictureCommunication': pictureCommunication,
        'shortSentences': shortSentences,
        'unlimitedTime': unlimitedTime,
        'keyboardOnlyNavigation': keyboardOnlyNavigation,
        'voiceControl': voiceControl,
        'eyeTrackingOptimized': eyeTrackingOptimized,
        'switchControl': switchControl,
        'noTimedInteractions': noTimedInteractions,
        'iconOnlyMode': iconOnlyMode,
        'verySimpleLanguage': verySimpleLanguage,
        'repetitionMode': repetitionMode,
        'rewardSystem': rewardSystem,
        'routineStructure': routineStructure,
        'maxOptionsCount3': maxOptionsCount3,
      };

  factory AccessibilityProfile.fromJson(Map<String, dynamic> j) {
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
}

/// تحويل نص disability_type من الـ API إلى enum
DisabilityType disabilityTypeFromString(String? s) {
  if (s == null || s.trim().isEmpty) return DisabilityType.none;
  final lower = s.toLowerCase();

  if (s.contains('عمى الألوان')) return DisabilityType.colorBlindness;

  if (s.contains('شبه كفيف') ||
      s.contains('كفيف كلي') ||
      s.contains('فقد عين واحدة') ||
      lower.contains('blind')) {
    return DisabilityType.blind;
  }

  if (s.startsWith('ضعف سمع') ||
      s.contains('أصم') ||
      s.contains('زارعي القوقعة') ||
      lower.contains('deaf')) {
    return DisabilityType.deaf;
  }

  if (s.contains('تأتأة') ||
      s.contains('تلعثم') ||
      lower.contains('stutter')) {
    return DisabilityType.stuttering;
  }

  if (s.contains('تأخر اللغة') ||
      s.contains('الحبسة') ||
      s.contains('تأخر النطق') ||
      s.contains('تأخر في الكلام') ||
      lower.contains('speech')) {
    return DisabilityType.speechDisorders;
  }

  if (s.startsWith('شلل') ||
      s.contains('استسقاء') ||
      s.contains('إصابات الحبل') ||
      s.contains('العظم الزجاجي')) {
    return DisabilityType.motorDisability;
  }

  if (s.contains('الصرع') || lower.contains('epilep')) {
    return DisabilityType.epilepsy;
  }

  if (s.contains('طيف التوحّد')) {
    if (s.contains('شديد')) return DisabilityType.autismSevere;
    return DisabilityType.autismMild;
  }

  if (s.contains('فرط الحركة') ||
      s.contains('تشتت الانتباه') ||
      lower.contains('adhd')) {
    return DisabilityType.adhd;
  }

  if (s.contains('اضطرابات سلوك')) return DisabilityType.adhd;

  if (s.contains('متلازمة داون') || lower.contains('down')) {
    return DisabilityType.downSyndrome;
  }

  if (s.contains('صعوبة تعلم') ||
      s.contains('تخلف عقلي') ||
      lower.contains('intellect')) {
    return DisabilityType.mildIntellectual;
  }

  if (s.contains('أمراض عصبية') ||
      s.contains('إصابات دماغ') ||
      s.contains('ضمور في الدماغ')) {
    return DisabilityType.epilepsy;
  }

  return DisabilityType.other;
}

/// التسميات العربية
const disabilityLabels = {
  DisabilityType.none: 'بدون تكييف',
  DisabilityType.adhd: 'فرط الحركة وتشتت الانتباه',
  DisabilityType.autismMild: 'طيف التوحّد (بسيط/متوسط)',
  DisabilityType.autismSevere: 'طيف التوحّد (شديد)',
  DisabilityType.downSyndrome: 'متلازمة داون',
  DisabilityType.blind: 'عمى / ضعف بصر شديد',
  DisabilityType.deaf: 'طرش / ضعف سمع',
  DisabilityType.stuttering: 'التأتأة (تلعثم الكلام)',
  DisabilityType.speechDisorders: 'اضطرابات النطق',
  DisabilityType.mildIntellectual: 'إعاقة ذهنية بسيطة',
  DisabilityType.colorBlindness: 'عمى الألوان',
  DisabilityType.epilepsy: 'الصرع',
  DisabilityType.motorDisability: 'إعاقة حركية',
  DisabilityType.multipleDisabilities: 'إعاقات متعددة',
  DisabilityType.other: 'أخرى',
};

/// الرموز التعبيرية
const disabilityEmojis = {
  DisabilityType.none: '⚪',
  DisabilityType.adhd: '⚡',
  DisabilityType.autismMild: '🧩',
  DisabilityType.autismSevere: '🧩',
  DisabilityType.downSyndrome: '💙',
  DisabilityType.blind: '👁️',
  DisabilityType.deaf: '👂',
  DisabilityType.stuttering: '🗣️',
  DisabilityType.speechDisorders: '💬',
  DisabilityType.mildIntellectual: '🧠',
  DisabilityType.colorBlindness: '🌈',
  DisabilityType.epilepsy: '⚕️',
  DisabilityType.motorDisability: '🦽',
  DisabilityType.multipleDisabilities: '♿',
  DisabilityType.other: '✏️',
};

// ═══════════════════════════════════════════════════════════
//  الخدمة الرئيسية
// ═══════════════════════════════════════════════════════════
class AccessibilityService {
  AccessibilityService._();
  static final AccessibilityService instance = AccessibilityService._();

  /// البروفايل المستخدم داخل شاشات الطفل المسموح لها بالتكييف
  /// (إعدادات الطفل + صفحة دروس الطفل فقط).
  final ValueNotifier<AccessibilityProfile> profile =
      ValueNotifier(const AccessibilityProfile(type: DisabilityType.none));

  /// بروفايل التطبيق العام. لا يتغيّر عند فتح طفل، حتى لا تنتقل
  /// إعدادات طفل إلى لوحة ولي الأمر أو التقييمات أو الألعاب أو باقي التطبيق.
  final ValueNotifier<AccessibilityProfile> applicationProfile =
      ValueNotifier(const AccessibilityProfile(type: DisabilityType.none));

  final ValueNotifier<int?> activeChildId = ValueNotifier(null);

  AccessibilityProfile _parentProfile =
      const AccessibilityProfile(type: DisabilityType.none);

  final Map<int, AccessibilityProfile> _childProfiles = {};

  static const _kParentKey = 'acc_parent_profile';
  static const _kChildKeyPrefix = 'acc_child_profile_';

  bool get isAdhd => profile.value.type == DisabilityType.adhd;
  bool get isAutism =>
      profile.value.type == DisabilityType.autismMild ||
      profile.value.type == DisabilityType.autismSevere;
  bool get isDown => profile.value.type == DisabilityType.downSyndrome;
  bool get isBlind => profile.value.type == DisabilityType.blind;
  bool get isDeaf => profile.value.type == DisabilityType.deaf;
  bool get isMotor => profile.value.type == DisabilityType.motorDisability;

  double get minTouchSize =>
      profile.value.extraLargeTouchTargets ? 88 : 56;

  Duration get animationDuration => profile.value.reducedAnimations
      ? const Duration(milliseconds: 80)
      : const Duration(milliseconds: 260);

  AccessibilityProfile? profileForChild(int childId) =>
      _childProfiles[childId];

  Map<int, AccessibilityProfile> get allChildProfiles =>
      Map.unmodifiable(_childProfiles);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final parentRaw = prefs.getString(_kParentKey);
    if (parentRaw != null) {
      try {
        _parentProfile = AccessibilityProfile.fromJson(
            jsonDecode(parentRaw) as Map<String, dynamic>);
      } catch (_) {}
    }

    final keys = prefs.getKeys().where((k) => k.startsWith(_kChildKeyPrefix));
    for (final key in keys) {
      final idStr = key.substring(_kChildKeyPrefix.length);
      final id = int.tryParse(idStr);
      if (id == null) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        _childProfiles[id] = AccessibilityProfile.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }

    profile.value = _parentProfile;
    applicationProfile.value = _parentProfile;
  }

  Future<void> _persistParent(AccessibilityProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kParentKey, jsonEncode(p.toJson()));
  }

  Future<void> _persistChild(int childId, AccessibilityProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kChildKeyPrefix$childId',
      jsonEncode(p.toJson()),
    );
  }

  /// يجهّز بروفايل طفل بدون تفعيله على أي شاشة.
  /// يفضّل نسخة السيرفر إن وُجدت، وإلا يستخدم النسخة المحلية أو الإعداد الموصى به.
  Future<AccessibilityProfile> ensureChildProfile(
    int childId, {
    String? disabilityTypeHint,
    bool forceReload = false,
  }) async {
    if (!forceReload && _childProfiles.containsKey(childId)) {
      return _childProfiles[childId]!;
    }

    try {
      final res =
          await ApiService.authGet('/children/$childId/accessibility-profile');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final raw = body is Map ? body['profile'] : null;
        if (raw is Map) {
          final remote = AccessibilityProfile.fromJson(
            Map<String, dynamic>.from(raw),
          );
          _childProfiles[childId] = remote;
          await _persistChild(childId, remote);
          return remote;
        }
      }
    } catch (_) {
      // العمل دون اتصال: نستخدم النسخة المحلية/الموصى بها.
    }

    final existing = _childProfiles[childId];
    if (existing != null) return existing;

    final type = disabilityTypeFromString(disabilityTypeHint);
    final customName =
        type == DisabilityType.other ? disabilityTypeHint : null;
    final created = AccessibilityProfile.recommendedFor(
      type,
      customName: customName,
    );
    _childProfiles[childId] = created;
    await _persistChild(childId, created);
    return created;
  }

  Future<void> setActiveChild(
    int? childId, {
    String? disabilityTypeHint,
    bool forceReload = false,
  }) async {
    activeChildId.value = childId;

    if (childId == null) {
      profile.value = _parentProfile;
      return;
    }

    final childProfile = await ensureChildProfile(
      childId,
      disabilityTypeHint: disabilityTypeHint,
      forceReload: forceReload,
    );

    // قد تُغلق الصفحة أثناء جلب الملف من الشبكة؛ لا تعِد تفعيل طفل قديم.
    if (activeChildId.value == childId) {
      profile.value = childProfile;
    }
  }

  Future<void> updateActive(AccessibilityProfile next) async {
    if (activeChildId.value == null) {
      _parentProfile = next;
      profile.value = next;
      applicationProfile.value = next;
      await _persistParent(next);
    } else {
      final id = activeChildId.value!;
      _childProfiles[id] = next;
      await _persistChild(id, next);
      profile.value = next;
    }
  }

  Future<void> updateForChild(
    int childId,
    AccessibilityProfile next,
  ) async {
    _childProfiles[childId] = next;

    // التغيير يظهر فوراً في صفحة إعدادات/دروس الطفل قبل انتظار الشبكة.
    if (activeChildId.value == childId) {
      profile.value = next;
    }

    await _persistChild(childId, next);

    // مزامنة كل طفل بمفتاحه الخاص على السيرفر. فشل الشبكة لا يلغي
    // التغيير المحلي ولا يخلط إعدادات الأطفال ببعضها.
    try {
      await ApiService.authPut(
        '/children/$childId/accessibility-profile',
        {'profile': next.toJson()},
      );
    } catch (_) {}
  }

  Future<void> applyRecommendedForChild(
    int childId,
    DisabilityType type, {
    String? customName,
  }) async {
    await updateForChild(
      childId,
      AccessibilityProfile.recommendedFor(type, customName: customName),
    );
  }

  Future<void> removeChild(int childId) async {
    _childProfiles.remove(childId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kChildKeyPrefix$childId');
    if (activeChildId.value == childId) {
      await setActiveChild(null);
    }
  }
}