// خدمة التكييف الديناميكي — تدعم بروفايل منفصل لكل طفل + ميزات كل الإعاقات
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility_profile.dart';
import 'api_service.dart';

export 'accessibility_profile.dart';

// ═══════════════════════════════════════════════════════════
//  الخدمة الرئيسية
// ═══════════════════════════════════════════════════════════
class AccessibilityService {
  AccessibilityService._();
  static final AccessibilityService instance = AccessibilityService._();

  /// البروفايل المستخدم داخل شاشات الطفل المسموح لها بالتكييف
  /// (الدروس والألعاب والواجبات وإعدادات الطفل).
  final ValueNotifier<AccessibilityProfile> profile =
      ValueNotifier(const AccessibilityProfile(type: DisabilityType.none));

  /// بروفايل التطبيق العام. لا يتغيّر عند فتح طفل، حتى لا تنتقل
  /// إعدادات طفل إلى لوحة ولي الأمر أو التقييمات أو باقي التطبيق.
  final ValueNotifier<AccessibilityProfile> applicationProfile =
      ValueNotifier(const AccessibilityProfile(type: DisabilityType.none));

  final ValueNotifier<int?> activeChildId = ValueNotifier(null);

  AccessibilityProfile _parentProfile =
      const AccessibilityProfile(type: DisabilityType.none);

  final Map<int, AccessibilityProfile> _childProfiles = {};

  int? _ownerId;
  int _session = 0;
  int _activationRequest = 0;
  final Map<int, int> _profileRequests = {};
  final Map<Object, int> _childScopes = {};
  int? _scopeParentChild;
  String get _kParentKey => 'acc_user_${_ownerId}_parent';
  String get _kChildKeyPrefix => 'acc_user_${_ownerId}_child_';

  void resetSession() {
    _session++;
    _activationRequest++;
    _childScopes.clear();
    _profileRequests.clear();
    _scopeParentChild = null;
    _ownerId = null;
    _childProfiles.clear();
    _parentProfile = const AccessibilityProfile(type: DisabilityType.none);
    activeChildId.value = null;
    profile.value = _parentProfile;
    applicationProfile.value = _parentProfile;
  }

  Future<void> _ensureAccount() async {
    final owner = await ApiService.getUserId();
    if (owner != _ownerId) await load();
  }

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

  Duration get animationDuration => (profile.value.reducedAnimations || profile.value.noFlashing)
      ? Duration.zero
      : const Duration(milliseconds: 260);

  AccessibilityProfile? profileForChild(int childId) =>
      _childProfiles[childId];

  Map<int, AccessibilityProfile> get allChildProfiles =>
      Map.unmodifiable(_childProfiles);

  Future<void> load() async {
    final pendingSession = _session;
    final owner = await ApiService.getUserId();
    if (pendingSession != _session) return;
    resetSession();
    _ownerId = owner;
    final session = _session;
    final prefs = await SharedPreferences.getInstance();
    if (session != _session || owner == null || owner <= 0) return;
    // Legacy caches were shared across accounts and cannot be assigned safely.
    for (final key in prefs.getKeys().where((key) =>
        key == 'acc_parent_profile' || key.startsWith('acc_child_profile_'))) {
      await prefs.remove(key);
    }
    if (session != _session) return;

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
    if (_ownerId == null) return;
    final key = _kParentKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(p.toJson()));
  }

  Future<void> _persistChild(int childId, AccessibilityProfile p) async {
    if (_ownerId == null) return;
    final key = '$_kChildKeyPrefix$childId';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
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
    await _ensureAccount();
    final session = _session;
    if (_ownerId == null) return _parentProfile;
    if (!forceReload && _childProfiles.containsKey(childId)) {
      return _childProfiles[childId]!;
    }

    final request = (_profileRequests[childId] ?? 0) + 1;
    _profileRequests[childId] = request;
    try {
      final res =
          await ApiService.authGet('/children/$childId/accessibility-profile');
      if (session != _session) return const AccessibilityProfile(type: DisabilityType.none);
      if (_profileRequests[childId] != request) {
        return _childProfiles[childId] ?? const AccessibilityProfile(type: DisabilityType.none);
      }
      if ([401, 403, 404].contains(res.statusCode)) {
        await removeChild(childId);
        return const AccessibilityProfile(type: DisabilityType.none);
      }
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

    if (session != _session) return const AccessibilityProfile(type: DisabilityType.none);
    final existing = _childProfiles[childId];
    if (existing != null) return existing;

    // No saved specialist configuration: do not infer adaptations from diagnosis.
    const created = AccessibilityProfile(type: DisabilityType.none);
    _childProfiles[childId] = created;
    await _persistChild(childId, created);
    return created;
  }

  Future<void> setActiveChild(
    int? childId, {
    String? disabilityTypeHint,
    bool forceReload = false,
  }) async {
    await _ensureAccount();
    final session = _session;
    final request = ++_activationRequest;
    activeChildId.value = childId;
    profile.value = _parentProfile;

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
    if (session == _session && request == _activationRequest && activeChildId.value == childId) {
      profile.value = childProfile;
    }
  }

  /// Own a child route without changing the account preferences. Nested routes
  /// restore their parent; a late disposal cannot restore a closed child route.
  Future<Object> enterChildScope(int childId) async {
    await _ensureAccount();
    final token = Object();
    if (_childScopes.isEmpty) _scopeParentChild = activeChildId.value;
    final refresh = activeChildId.value != childId;
    _childScopes[token] = childId;
    try {
      await setActiveChild(childId, forceReload: refresh);
      return token;
    } catch (_) {
      await leaveChildScope(token);
      rethrow;
    }
  }

  Future<void> leaveChildScope(Object token) async {
    if (!_childScopes.containsKey(token)) return;
    final wasCurrent = identical(_childScopes.keys.last, token);
    final childId = _childScopes.remove(token);
    if (!wasCurrent) return;
    final restore = _childScopes.isEmpty ? _scopeParentChild : _childScopes.values.last;
    if (_childScopes.isEmpty) _scopeParentChild = null;
    // Another explicit navigation/account transition already owns the profile.
    if (activeChildId.value != childId) return;
    await setActiveChild(restore);
  }

  Future<void> updateActive(AccessibilityProfile next) async {
    await _ensureAccount();
    if (activeChildId.value == null) {
      _parentProfile = next;
      profile.value = next;
      applicationProfile.value = next;
      await _persistParent(next);
    } else {
      final id = activeChildId.value!;
      await updateForChild(id, next);
    }
  }

  Future<void> updateForChild(
    int childId,
    AccessibilityProfile next,
  ) async {
    await _ensureAccount();
    final session = _session;
    if (await ApiService.getRole() != 'specialist') {
      throw StateError('تعديل التكيف متاح للمختص فقط');
    }
    if (_ownerId == null || session != _session) throw StateError('انتهت جلسة الحساب');
    // The API also checks assignment to this child. Persist locally only after
    // authorization succeeds, so read-only users cannot override the profile.
    final response = await ApiService.authPut(
      '/children/$childId/accessibility-profile',
      {'profile': next.toJson()},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('تعذّر حفظ إعدادات التكيف');
    }
    if (session != _session) throw StateError('انتهت جلسة الحساب');
    _childProfiles[childId] = next;
    await _persistChild(childId, next);
    if (session == _session && activeChildId.value == childId) profile.value = next;
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
    final key = '$_kChildKeyPrefix$childId';
    _childProfiles.remove(childId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    if (activeChildId.value == childId) {
      await setActiveChild(null);
    }
  }
}