// خدمة التكييف الديناميكي — تدعم بروفايل منفصل لكل طفل
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  other,
}

/// بروفايل التكييف لكل طفل
class AccessibilityProfile {
  final DisabilityType type;
  final String? customDisabilityName;

  // ─── الميزات الأساسية ───
  final bool brainBreaksEnabled;
  final int brainBreakIntervalMinutes;
  final bool visualTimerEnabled;
  final int timerRenewalMinutes;      // ✅ جديد — كل كم دقيقة يتجدّد المؤقّت
  final bool reducedAnimations;
  final bool predictableTimeline;
  final bool sensoryCalmMode;
  final bool extraLargeTouchTargets;
  final bool autoReadOnTap;
  final bool simpleIconsGrid;
  final bool highContrast;
  final bool gestureNavigationEnabled;
  final bool visualAlertsEnabled;

  // ─── الخصائص الخاصة ───
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

  const AccessibilityProfile({
    required this.type,
    this.customDisabilityName,
    this.brainBreaksEnabled = false,
    this.brainBreakIntervalMinutes = 15,
    this.visualTimerEnabled = false,
    this.timerRenewalMinutes = 5,        // ✅ افتراضي 5 دقائق
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
  });

  AccessibilityProfile copyWith({
    DisabilityType? type,
    String? customDisabilityName,
    bool? brainBreaksEnabled,
    int? brainBreakIntervalMinutes,
    bool? visualTimerEnabled,
    int? timerRenewalMinutes,            // ✅ جديد
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
  }) {
    return AccessibilityProfile(
      type: type ?? this.type,
      customDisabilityName: customDisabilityName ?? this.customDisabilityName,
      brainBreaksEnabled: brainBreaksEnabled ?? this.brainBreaksEnabled,
      brainBreakIntervalMinutes:
          brainBreakIntervalMinutes ?? this.brainBreakIntervalMinutes,
      visualTimerEnabled: visualTimerEnabled ?? this.visualTimerEnabled,
      timerRenewalMinutes: timerRenewalMinutes ?? this.timerRenewalMinutes, // ✅
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
    );
  }

  /// البروفايل المُوصى به لكل نوع إعاقة
  factory AccessibilityProfile.recommendedFor(
    DisabilityType type, {
    String? customName,
  }) {
    switch (type) {
      // ═══════════════════════════════════════
      // 1. ADHD
      // ═══════════════════════════════════════
      case DisabilityType.adhd:
        return const AccessibilityProfile(
          type: DisabilityType.adhd,
          brainBreaksEnabled: true,
          visualTimerEnabled: true,
          brainBreakIntervalMinutes: 12,
          timerRenewalMinutes: 5,
          reducedAnimations: true,
        );

      // ═══════════════════════════════════════
      // 2. توحّد
      // ═══════════════════════════════════════
      case DisabilityType.autismMild:
        return const AccessibilityProfile(
          type: DisabilityType.autismMild,
          predictableTimeline: true,
          reducedAnimations: true,
          timerRenewalMinutes: 10,
        );

      case DisabilityType.autismSevere:
        return const AccessibilityProfile(
          type: DisabilityType.autismSevere,
          predictableTimeline: true,
          reducedAnimations: true,
          sensoryCalmMode: true,
          timerRenewalMinutes: 10,
        );

      // ═══════════════════════════════════════
      // 3. داون
      // ═══════════════════════════════════════
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
        );

      // ═══════════════════════════════════════
      // 4. أعمى
      // ═══════════════════════════════════════
      case DisabilityType.blind:
        return const AccessibilityProfile(
          type: DisabilityType.blind,
          highContrast: true,
          gestureNavigationEnabled: true,
          autoReadOnTap: true,
          visualTimerEnabled: true,
          timerRenewalMinutes: 5,
        );

      // ═══════════════════════════════════════
      // 5. أصمّ
      // ═══════════════════════════════════════
      case DisabilityType.deaf:
        return const AccessibilityProfile(
          type: DisabilityType.deaf,
          visualAlertsEnabled: true,
          timerRenewalMinutes: 5,
        );

      // ═══════════════════════════════════════
      // 6. تأتأة
      // ═══════════════════════════════════════
      case DisabilityType.stuttering:
        return const AccessibilityProfile(
          type: DisabilityType.stuttering,
          slowSpeech: true,
          rhythmReading: true,
          noTimers: true,
          reducedAnimations: true,
          autoReadOnTap: true,
          timerRenewalMinutes: 5,
        );

      // ═══════════════════════════════════════
      // 7. اضطرابات نطق
      // ═══════════════════════════════════════
      case DisabilityType.speechDisorders:
        return const AccessibilityProfile(
          type: DisabilityType.speechDisorders,
          speechExercises: true,
          slowSpeech: true,
          noTimers: true,
          autoReadOnTap: true,
          timerRenewalMinutes: 5,
        );

      // ═══════════════════════════════════════
      // 8. إعاقة ذهنية بسيطة
      // ═══════════════════════════════════════
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
        );

      // ═══════════════════════════════════════
      // 9. عمى ألوان
      // ═══════════════════════════════════════
      case DisabilityType.colorBlindness:
        return const AccessibilityProfile(
          type: DisabilityType.colorBlindness,
          colorSymbols: true,
          colorPatterns: true,
          colorFiltersEnabled: true,
          timerRenewalMinutes: 5,
        );

      // ═══════════════════════════════════════
      // 10. صرع
      // ═══════════════════════════════════════
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
      // 11. أخرى
      // ═══════════════════════════════════════
      case DisabilityType.other:
        return AccessibilityProfile(
          type: DisabilityType.other,
          customDisabilityName: customName,
          reducedAnimations: true,
          extraLargeTouchTargets: true,
          autoReadOnTap: true,
          timerRenewalMinutes: 5,
        );

      // ═══════════════════════════════════════
      // 12. بدون
      // ═══════════════════════════════════════
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
        'timerRenewalMinutes': timerRenewalMinutes,      // ✅
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
      timerRenewalMinutes: j['timerRenewalMinutes'] ?? 5,  // ✅
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
    );
  }
}

/// تحويل نص disability_type من الـ API إلى enum
DisabilityType disabilityTypeFromString(String? s) {
  if (s == null || s.trim().isEmpty) return DisabilityType.none;
  final lower = s.toLowerCase();

  if (lower.contains('adhd') || s.contains('فرط') || s.contains('تشتت')) {
    return DisabilityType.adhd;
  }
  if (s.contains('توحد') || s.contains('توحّد') || lower.contains('autis')) {
    if (s.contains('شديد') || lower.contains('severe')) {
      return DisabilityType.autismSevere;
    }
    return DisabilityType.autismMild;
  }
  if (s.contains('داون') || lower.contains('down')) {
    return DisabilityType.downSyndrome;
  }
  if (lower.contains('blind') || s.contains('عمى')) {
    return DisabilityType.blind;
  }
  if (lower.contains('deaf') || s.contains('طرش')) {
    return DisabilityType.deaf;
  }
  if (lower.contains('stutter') || s.contains('تأتأة') || s.contains('تلعثم')) {
    return DisabilityType.stuttering;
  }
  if (lower.contains('speech') || s.contains('نطق') || s.contains('لثغة')) {
    return DisabilityType.speechDisorders;
  }
  if (lower.contains('intellect') ||
      s.contains('ذهنية') ||
      s.contains('عقلية') ||
      s.contains('إعاقة بسيطة')) {
    return DisabilityType.mildIntellectual;
  }
  if ((lower.contains('color') && lower.contains('blind')) ||
      s.contains('عمى الألوان') ||
      s.contains('عمى ألوان')) {
    return DisabilityType.colorBlindness;
  }
  if (lower.contains('epilep') || s.contains('صرع')) {
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
  DisabilityType.other: 'أخرى (يُحدّدها ولي الأمر)',
};

/// الرموز التعبيرية لكل نوع
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
  DisabilityType.other: '✏️',
};

// ═══════════════════════════════════════════════════════════
//  الخدمة الرئيسية
// ═══════════════════════════════════════════════════════════
class AccessibilityService {
  AccessibilityService._();
  static final AccessibilityService instance = AccessibilityService._();

  final ValueNotifier<AccessibilityProfile> profile =
      ValueNotifier(const AccessibilityProfile(type: DisabilityType.none));

  final ValueNotifier<int?> activeChildId = ValueNotifier(null);

  AccessibilityProfile _parentProfile =
      const AccessibilityProfile(type: DisabilityType.none);

  final Map<int, AccessibilityProfile> _childProfiles = {};

  static const _kParentKey = 'acc_parent_profile';
  static const _kChildKeyPrefix = 'acc_child_profile_';

  // ═══════════════════════════════════════════════════════
  //  الوصول السريع
  // ═══════════════════════════════════════════════════════
  bool get isAdhd => profile.value.type == DisabilityType.adhd;
  bool get isAutism =>
      profile.value.type == DisabilityType.autismMild ||
      profile.value.type == DisabilityType.autismSevere;
  bool get isDown => profile.value.type == DisabilityType.downSyndrome;
  bool get isBlind => profile.value.type == DisabilityType.blind;
  bool get isDeaf => profile.value.type == DisabilityType.deaf;

  double get minTouchSize =>
      profile.value.extraLargeTouchTargets ? 88 : 56;

  Duration get animationDuration => profile.value.reducedAnimations
      ? const Duration(milliseconds: 80)
      : const Duration(milliseconds: 260);

  AccessibilityProfile? profileForChild(int childId) =>
      _childProfiles[childId];

  Map<int, AccessibilityProfile> get allChildProfiles =>
      Map.unmodifiable(_childProfiles);

  // ═══════════════════════════════════════════════════════
  //  التحميل والحفظ
  // ═══════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════
  //  تبديل الطفل النشط
  // ═══════════════════════════════════════════════════════
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

    if (forceReload || !_childProfiles.containsKey(childId)) {
      final type = disabilityTypeFromString(disabilityTypeHint);
      final customName =
          type == DisabilityType.other ? disabilityTypeHint : null;

      final created = AccessibilityProfile.recommendedFor(
        type,
        customName: customName,
      );

      _childProfiles[childId] = created;
      await _persistChild(childId, created);
    }

    profile.value = _childProfiles[childId]!;
  }

  // ═══════════════════════════════════════════════════════
  //  التحديث
  // ═══════════════════════════════════════════════════════
  Future<void> updateActive(AccessibilityProfile next) async {
    if (activeChildId.value == null) {
      _parentProfile = next;
      await _persistParent(next);
      profile.value = next;
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
    await _persistChild(childId, next);
    if (activeChildId.value == childId) {
      profile.value = next;
    }
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