import 'dart:async';
import 'dart:convert';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/child_adaptation_scope.dart';
import 'package:edubridge_app/widgets/accessibility/brain_break_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AccessibilityService.instance;
  const firstProfile = AccessibilityProfile(type: DisabilityType.none, extraLargeTouchTargets: true);
  const secondProfile = AccessibilityProfile(type: DisabilityType.none, sensoryCalmMode: true);
  setUp(() async {
    service.resetSession();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 1});
    await service.load();
  });
  tearDown(service.resetSession);
  http.Client client() => MockClient((request) async => http.Response(jsonEncode({
    'profile': request.url.path.contains('/9/') ? firstProfile.toJson() : secondProfile.toJson(),
  }), 200));

  test('nested routes restore the previous child without changing account settings', () async {
    await http.runWithClient(() async {
      final first = await service.enterChildScope(9);
      final nested = await service.enterChildScope(9);
      final second = await service.enterChildScope(10);
      expect(service.profile.value.sensoryCalmMode, isTrue);
      await service.leaveChildScope(second);
      expect(service.activeChildId.value, 9);
      expect(service.profile.value.extraLargeTouchTargets, isTrue);
      await service.leaveChildScope(nested);
      expect(service.activeChildId.value, 9);
      await service.leaveChildScope(first);
      expect(service.activeChildId.value, isNull);
      expect(service.applicationProfile.value.toJson(), const AccessibilityProfile(type: DisabilityType.none).toJson());
    }, client);
  });

  test('disposing an older route cannot reactivate a closed child', () async {
    await http.runWithClient(() async {
      final first = await service.enterChildScope(9);
      final second = await service.enterChildScope(10);
      await service.leaveChildScope(first);
      expect(service.activeChildId.value, 10);
      await service.leaveChildScope(second);
      expect(service.activeChildId.value, isNull);
    }, client);
  });

  test('logout discards leases so closing old screens cannot restore a child', () async {
    await http.runWithClient(() async {
      final token = await service.enterChildScope(9);
      service.resetSession();
      await service.leaveChildScope(token);
      expect(service.activeChildId.value, isNull);
      expect(service.allChildProfiles, isEmpty);
    }, client);
  });

  test('a late response for the same child cannot overwrite newer activation', () async {
    final started = Completer<void>();
    final oldResponse = Completer<http.Response>();
    var requests = 0;
    await http.runWithClient(() async {
      final old = service.setActiveChild(9, forceReload: true);
      await started.future;
      await service.setActiveChild(9, forceReload: true);
      expect(service.profile.value.sensoryCalmMode, isTrue);
      oldResponse.complete(http.Response(jsonEncode({'profile': firstProfile.toJson()}), 200));
      await old;
      expect(service.profile.value.sensoryCalmMode, isTrue);
      expect(service.allChildProfiles[9]!.sensoryCalmMode, isTrue);
    }, () => MockClient((_) {
      if (++requests == 1) { started.complete(); return oldResponse.future; }
      return Future.value(http.Response(jsonEncode({'profile': secondProfile.toJson()}), 200));
    }));
  });

  testWidgets('scope builds content only after the child profile is loaded', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: ChildAdaptationScope(childId: 9,
        builder: (_) => Text(service.profile.value.extraLargeTouchTargets ? 'كبير' : 'عادي'))));
      await tester.pumpAndSettle();
      expect(find.text('كبير'), findsOneWidget);
      expect(find.text('عادي'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(service.activeChildId.value, isNull);
    }, client);
  });

  testWidgets('account break scheduler pauses while a child owns the session', (tester) async {
    service.applicationProfile.value = const AccessibilityProfile(type: DisabilityType.none,
      brainBreaksEnabled: true, brainBreakIntervalMinutes: 1, sensoryCalmMode: true);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      BrainBreakScheduler(child: Text('المحتوى')))));
    service.activeChildId.value = 9;
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('وقت الراحة'), findsNothing);
    service.activeChildId.value = null;
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('وقت الراحة'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
