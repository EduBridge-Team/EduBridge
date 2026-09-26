// نماذج وإعدادات التكييف الديناميكي المشتركة.
part 'accessibility_profile_factories.dart';

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
  }) =>
      _recommendedAccessibilityProfile(type, customName: customName);

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

  factory AccessibilityProfile.fromJson(Map<String, dynamic> j) =>
      _accessibilityProfileFromJson(j);
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
