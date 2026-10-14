import 'dart:async';
import 'dart:convert';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/screens/child_accessibility/child_accessibility_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('controls wait for both permission and the saved profile', (tester) async {
    final requests = <Completer<http.Response>>[];
    final started = Completer<void>();
    final loaded = Completer<void>();
    void onProfile() {
      if (service.profile.value.noTimers && !loaded.isCompleted) loaded.complete();
    }
    service.profile.addListener(onProfile);
    addTearDown(() => service.profile.removeListener(onProfile));
    await tester.runAsync(() async {
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: ChildAccessibilitySettingsScreen(
          childId: 9, childName: 'محمود')));
        await started.future.timeout(const Duration(seconds: 10));
        requests.first.complete(http.Response(jsonEncode({'can_edit': true,
          'profile': const AccessibilityProfile(type: DisabilityType.none, noTimers: true).toJson()}), 200));
        await Future<void>.delayed(Duration.zero);
        expect(find.byType(SwitchListTile), findsNothing);
        requests.last.complete(http.Response(jsonEncode({'can_edit': true,
          'profile': const AccessibilityProfile(type: DisabilityType.none, noTimers: true).toJson()}), 200));
        await loaded.future.timeout(const Duration(seconds: 10));
      }, () => MockClient((_) {
        final response = Completer<http.Response>();
        requests.add(response);
        if (requests.length == 2) started.complete();
        return response.future;
      }));
    });
    await tester.pumpAndSettle();
    expect(find.text('إعدادات محمود'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsWidgets);
    expect(service.profile.value.noTimers, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
