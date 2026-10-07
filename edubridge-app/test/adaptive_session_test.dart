import 'dart:async';
import 'dart:convert';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AccessibilityService.instance;
  setUp(() {
    service.resetSession();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 1});
  });
  tearDown(service.resetSession);

  test('accounts load only their own caches and discard ambiguous legacy caches', () async {
    const blind = AccessibilityProfile(type: DisabilityType.blind, highContrast: true);
    SharedPreferences.setMockInitialValues({
      'userId': 1,
      'acc_parent_profile': jsonEncode(blind.toJson()),
      'acc_child_profile_9': jsonEncode(blind.toJson()),
      'acc_user_1_parent': jsonEncode(blind.toJson()),
      'acc_user_1_child_9': jsonEncode(blind.toJson()),
    });
    await service.load();
    expect(service.applicationProfile.value.type, DisabilityType.blind);
    expect(service.profileForChild(9)?.type, DisabilityType.blind);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('acc_child_profile_9'), isFalse);
    await prefs.setInt('userId', 2);
    await service.load();
    expect(service.allChildProfiles, isEmpty);
    expect(service.applicationProfile.value.type, DisabilityType.none);
    await prefs.setInt('userId', 1);
    await service.load();
    expect(service.profileForChild(9)?.type, DisabilityType.blind);
    service.resetSession();
    expect(service.allChildProfiles, isEmpty);
    expect(service.activeChildId.value, isNull);
    expect(service.profile.value.type, DisabilityType.none);
  });

  test('access denial clears the cache rather than treating it as offline', () async {
    const profile = AccessibilityProfile(type: DisabilityType.deaf);
    SharedPreferences.setMockInitialValues({'userId': 1, 'acc_user_1_child_9': jsonEncode(profile.toJson())});
    await service.load();
    await http.runWithClient(() async {
      final result = await service.ensureChildProfile(9, forceReload: true, disabilityTypeHint: 'deaf');
      expect(result.type, DisabilityType.none);
      expect(service.profileForChild(9), isNull);
      expect((await SharedPreferences.getInstance()).containsKey('acc_user_1_child_9'), isFalse);
    }, () => MockClient((_) async => http.Response('{}', 403)));
  });

  test('an in-flight child response cannot repopulate a cleared session', () async {
    await service.load();
    final started = Completer<void>();
    final response = Completer<http.Response>();
    await http.runWithClient(() async {
      final pending = service.setActiveChild(9, forceReload: true);
      await started.future;
      service.resetSession();
      response.complete(http.Response(jsonEncode({'profile': const AccessibilityProfile(type: DisabilityType.deaf).toJson()}), 200));
      await pending;
      expect(service.allChildProfiles, isEmpty);
      expect(service.activeChildId.value, isNull);
      expect(service.profile.value.type, DisabilityType.none);
    }, () => MockClient((_) { started.complete(); return response.future; }));
  });
}
