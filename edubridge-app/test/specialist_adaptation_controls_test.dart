import 'dart:async';
import 'dart:convert';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/screens/child_accessibility/child_accessibility_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubridge_app/features/adaptation/data/adaptation_settings_loader.dart';
import 'package:edubridge_app/features/adaptation/data/adaptation_permission_repository.dart';

void main() {
  final service = AccessibilityService.instance;
  setUp(() async {
    service.resetSession();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 2, 'role': 'specialist'});
    await service.load();
  });
  tearDown(service.resetSession);

  testWidgets('duration selector retains non-preset values at large text sizes', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(
      data: const MediaQueryData(size: Size(320, 600), textScaler: TextScaler.linear(2)),
      child: SizedBox(width: 320, child: buildDurationSetting(
        title: 'الفترة بين الاستراحات', subtitle: 'تحديد مدة التعلم قبل الاستراحة',
        value: 17, choices: const [5, 10, 15, 30], unit: 'دقيقة', onChanged: (_) {})),
    ))));
    expect(find.text('17 دقيقة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled duration selector cannot change saved preferences', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: buildDurationSetting(
      title: 'مدة مؤقّت المهمة', subtitle: 'المؤقّت معطّل', value: 5,
      choices: const [1, 5, 10], unit: 'دقيقة', onChanged: null))));
    final dropdown = tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
    expect(dropdown.onChanged, isNull);
    expect(dropdown.value, 5);
  });

  for (final permissionFirst in [true, false]) {
    test('settings readiness waits for both loads, permissionFirst=$permissionFirst', () async {
      final profileReady = Completer<void>();
      final permissionReady = Completer<http.Response>();
      final loader = AdaptationSettingsLoader(
        permissions: AdaptationPermissionRepository(get: (_) => permissionReady.future),
        activateChild: (id, hint) {
          expect(id, 9);
          expect(hint, 'أخرى');
          return profileReady.future;
        },
      );
      var finished = false;
      final loaded = loader.load(9, disabilityHint: 'أخرى').then((allowed) {
        finished = true;
        return allowed;
      });
      final response = http.Response(jsonEncode({'can_edit': true}), 200);
      if (permissionFirst) {
        permissionReady.complete(response);
      } else {
        profileReady.complete();
      }
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      if (permissionFirst) {
        profileReady.complete();
      } else {
        permissionReady.complete(response);
      }
      expect(await loaded, isTrue);
    });
  }

  test('profile readiness never overrides a denied permission', () async {
    final loader = AdaptationSettingsLoader(
      permissions: AdaptationPermissionRepository(get: (_) async => http.Response('{"can_edit":false}', 200)),
      activateChild: (_, __) async {},
    );
    expect(await loader.load(9), isFalse);
  });
  test('profile loading failure is propagated for the screen retry', () async {
    final loader = AdaptationSettingsLoader(
      permissions: AdaptationPermissionRepository(get: (_) async => http.Response('{"can_edit":true}', 200)),
      activateChild: (_, __) async => throw StateError('Unable to load'),
    );
    await expectLater(loader.load(9), throwsStateError);
  });

}
