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
}

/// بروفايل التكييف لكل طفل
class AccessibilityProfile {
  final DisabilityType type;
  final bool brainBreaksEnabled;
  final int brainBreakIntervalMinutes;
  final bool visualTimerEnabled;
  final bool reducedAnimations;
  final bool predictableTimeline;
  final bool sensoryCalmMode;
  final bool extraLargeTouchTargets;
  final bool autoReadOnTap;
  final bool simpleIconsGrid;
  final bool highContrast;
  final bool gestureNavigationEnabled;
  final bool visualAlertsEnabled;

  const AccessibilityProfile({
    required this.type,
    this.brainBreaksEnabled = false,
    this.brainBreakIntervalMinutes = 15,
    this.visualTimerEnabled = false,
    this.reducedAnimations = false,
    this.predictableTimeline = false,
    this.sensoryCalmMode = false,
    this.extraLargeTouchTargets = false,
    this.autoReadOnTap = false,
    this.simpleIconsGrid = false,
    this.highContrast = false,
    this.gestureNavigationEnabled = false,
    this.visualAlertsEnabled = false,
  });

  AccessibilityProfile copyWith({
    DisabilityType? type,
    bool? brainBreaksEnabled,
    int? brainBreakIntervalMinutes,
    bool? visualTimerEnabled,
    bool? reducedAnimations,
    bool? predictableTimeline,
    bool? sensoryCalmMode,
    bool? extraLargeTouchTargets,
    bool? autoReadOnTap,
    bool? simpleIconsGrid,
    bool? highContrast,
    bool? gestureNavigationEnabled,
    bool? visualAlertsEnabled,
  }) {
    return AccessibilityProfile(
      type: type ?? this.type,
      brainBreaksEnabled: brainBreaksEnabled ?? this.brainBreaksEnabled,
      brainBreakIntervalMinutes:
          brainBreakIntervalMinutes ?? this.brainBreakIntervalMinutes,
      visualTimerEnabled: visualTimerEnabled ?? this.visualTimerEnabled,
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
    );
  }

  factory AccessibilityProfile.recommendedFor(DisabilityType type) {
    switch (type) {
      case DisabilityType.adhd:
        return const AccessibilityProfile(
          type: DisabilityType.adhd,
          brainBreaksEnabled: true,
          visualTimerEnabled: true,
          brainBreakIntervalMinutes: 12,
          reducedAnimations: true,
        );
      case DisabilityType.autismMild:
        return const AccessibilityProfile(
          type: DisabilityType.autismMild,
          predictableTimeline: true,
          reducedAnimations: true,
        );
      case DisabilityType.autismSevere:
        return const AccessibilityProfile(
          type: DisabilityType.autismSevere,
          predictableTimeline: true,
          reducedAnimations: true,
          sensoryCalmMode: true,
        );
      case DisabilityType.downSyndrome:
        return const AccessibilityProfile(
          type: DisabilityType.downSyndrome,
          extraLargeTouchTargets: true,
          autoReadOnTap: true,
          simpleIconsGrid: true,
          reducedAnimations: true,
        );
      case DisabilityType.blind:
        return const AccessibilityProfile(
          type: DisabilityType.blind,
          highContrast: true,
          gestureNavigationEnabled: true,
          autoReadOnTap: true,
        );
      case DisabilityType.deaf:
        return const AccessibilityProfile(
          type: DisabilityType.deaf,
          visualAlertsEnabled: true,
        );
      case DisabilityType.none:
        return const AccessibilityProfile(type: DisabilityType.none);
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'brainBreaksEnabled': brainBreaksEnabled,
        'brainBreakIntervalMinutes': brainBreakIntervalMinutes,
        'visualTimerEnabled': visualTimerEnabled,
        'reducedAnimations': reducedAnimations,
        'predictableTimeline': predictableTimeline,
        'sensoryCalmMode': sensoryCalmMode,
        'extraLargeTouchTargets': extraLargeTouchTargets,
        'autoReadOnTap': autoReadOnTap,
        'simpleIconsGrid': simpleIconsGrid,
        'highContrast': highContrast,
        'gestureNavigationEnabled': gestureNavigationEnabled,
        'visualAlertsEnabled': visualAlertsEnabled,
      };

  factory AccessibilityProfile.fromJson(Map<String, dynamic> j) {
    return AccessibilityProfile(
      type: DisabilityType.values.firstWhere(
        (e) => e.name == j['type'],
        orElse: () => DisabilityType.none,
      ),
      brainBreaksEnabled: j['brainBreaksEnabled'] ?? false,
      brainBreakIntervalMinutes: j['brainBreakIntervalMinutes'] ?? 15,
      visualTimerEnabled: j['visualTimerEnabled'] ?? false,
      reducedAnimations: j['reducedAnimations'] ?? false,
      predictableTimeline: j['predictableTimeline'] ?? false,
      sensoryCalmMode: j['sensoryCalmMode'] ?? false,
      extraLargeTouchTargets: j['extraLargeTouchTargets'] ?? false,
      autoReadOnTap: j['autoReadOnTap'] ?? false,
      simpleIconsGrid: j['simpleIconsGrid'] ?? false,
      highContrast: j['highContrast'] ?? false,
      gestureNavigationEnabled: j['gestureNavigationEnabled'] ?? false,
      visualAlertsEnabled: j['visualAlertsEnabled'] ?? false,
    );
  }
}

/// تحويل نص disability_type القادم من الـ API إلى enum
DisabilityType disabilityTypeFromString(String? s) {
  if (s == null || s.trim().isEmpty) return DisabilityType.none;
  final lower = s.toLowerCase();
  if (lower.contains('adhd') || s.contains('فرط') || s.contains('تشتت')) {
    return DisabilityType.adhd;
  }
  if (s.contains('توحد') || lower.contains('autis')) {
    if (s.contains('شديد') || lower.contains('severe')) {
      return DisabilityType.autismSevere;
    }
    return DisabilityType.autismMild;
  }
  if (s.contains('داون') ||
      lower.contains('down') ||
      s.contains('عقلية') ||
      s.contains('ذهنية') ||
      lower.contains('intellect')) {
    return DisabilityType.downSyndrome;
  }
  if (lower.contains('blind') || s.contains('عمى') || s.contains('بصر')) {
    return DisabilityType.blind;
  }
  if (lower.contains('deaf') || s.contains('طرش') || s.contains('سمع')) {
    return DisabilityType.deaf;
  }
  return DisabilityType.none;
}

const disabilityLabels = {
  DisabilityType.none: 'بدون تكييف',
  DisabilityType.adhd: 'فرط الحركة وتشتت الانتباه',
  DisabilityType.autismMild: 'طيف التوحّد (بسيط/متوسط)',
  DisabilityType.autismSevere: 'طيف التوحّد (شديد)',
  DisabilityType.downSyndrome: 'متلازمة داون / إعاقة ذهنية',
  DisabilityType.blind: 'عمى / ضعف بصر شديد',
  DisabilityType.deaf: 'طرش / ضعف سمع',
};

class AccessibilityService {
  AccessibilityService._();
  static final AccessibilityService instance = AccessibilityService._();

  /// البروفايل النشط حالياً
  final ValueNotifier<AccessibilityProfile> profile =
      ValueNotifier(const AccessibilityProfile(type: DisabilityType.none));

  /// معرّف الطفل المعروض حالياً (null = واجهة ولي الأمر الرئيسية)
  final ValueNotifier<int?> activeChildId = ValueNotifier(null);

  AccessibilityProfile _parentProfile =
      const AccessibilityProfile(type: DisabilityType.none);

  final Map<int, AccessibilityProfile> _childProfiles = {};

  static const _kParentKey = 'acc_parent_profile';
  static const _kChildKeyPrefix = 'acc_child_profile_';

  // ============ الوصول السريع ============
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

  // ============ التحميل والحفظ ============
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

  // ============ تبديل الطفل النشط ============
  Future<void> setActiveChild(
    int? childId, {
    String? disabilityTypeHint,
  }) async {
    activeChildId.value = childId;

    if (childId == null) {
      profile.value = _parentProfile;
      return;
    }

    if (!_childProfiles.containsKey(childId)) {
      final type = disabilityTypeFromString(disabilityTypeHint);
      final created = AccessibilityProfile.recommendedFor(type);
      _childProfiles[childId] = created;
      await _persistChild(childId, created);
    }

    profile.value = _childProfiles[childId]!;
  }

  // ============ التحديث ============
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
    DisabilityType type,
  ) async {
    await updateForChild(
        childId, AccessibilityProfile.recommendedFor(type));
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