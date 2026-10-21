import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/utils/adaptive_helper.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_button.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_icon.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_wrapper.dart';
import 'package:edubridge_app/widgets/accessibility/large_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> host(WidgetTester tester, String language, Widget child, {bool settle = true}) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, body) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(2)), child: body!),
    home: Scaffold(body: Center(child: child))));
  if (settle) { await tester.pumpAndSettle(); } else { await tester.pump(); }
}
void main() {
  testWidgets('shared controls follow locale and explicit content voice while keeping actions and calm/slow rules', (tester) async {
    final service = AccessibilityService.instance;
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      autoReadOnTap: true, slowSpeech: true);
    addTearDown(service.resetSession);
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { calls.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    String spoken() {
      final args = calls.where((c) => c.method == 'speak').last.arguments;
      return (args is Map ? args['text'] : args) as String;
    }
    for (final kind in ['button','icon','large']) {
      var actions = 0;
      Widget control({String label = 'Continue', String? voice}) => switch (kind) {
        'button' => AdaptiveButton(label: label, onPressed: () => actions++, speechLanguageCode: voice),
        'icon' => AdaptiveIcon(Icons.home, semanticLabel: label, speechLanguageCode: voice),
        _ => LargeActionButton(icon: Icons.home, label: label, onTap: () => actions++, speechLanguageCode: voice),
      };
      Finder finder() => switch (kind) {
        'button' => find.byType(AdaptiveButton),
        'icon' => find.byType(AdaptiveIcon),
        _ => find.byType(LargeActionButton),
      };
      for (final language in ['ar','en']) {
        await host(tester, language, control());
        calls.clear();
        await tester.tap(finder()); await tester.pumpAndSettle();
        expect(calls.where((c) => c.method == 'setLanguage').last.arguments, language);
        expect(calls.where((c) => c.method == 'setSpeechRate').last.arguments, 0.30);
        expect(spoken(), 'Continue');
        await tester.pump(const Duration(milliseconds: 400));
      }
      if (kind != 'icon') expect(actions, 2);
      await host(tester, 'en', control(label: 'محتوى أصلي', voice: 'ar'));
      calls.clear();
      await tester.tap(finder()); await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
      expect(spoken(), 'محتوى أصلي');
      await tester.pump(const Duration(milliseconds: 400));
      service.profile.value = service.profile.value.copyWith(sensoryCalmMode: true);
      await tester.pump(); calls.clear();
      final before = actions;
      await tester.tap(finder()); await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'speak'), isEmpty);
      if (kind != 'icon') expect(actions, before + 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      service.profile.value = service.profile.value.copyWith(sensoryCalmMode: false);
    }
    var actions = 0;
    await host(tester, 'en', AdaptiveButton(label: 'Continue', onPressed: () => actions++));
    calls.clear();
    await tester.tap(find.byType(AdaptiveButton));
    await tester.tap(find.byType(AdaptiveButton));
    await tester.pump();
    expect(actions, 1);
    expect(calls.where((c) => c.method == 'speak'), hasLength(1));
    await tester.pump(const Duration(milliseconds: 400));
    await host(tester, 'en', AdaptiveButton(label: 'Continue', isBusy: true, onPressed: () => actions++), settle: false);
    calls.clear();
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
    expect(actions, 1);
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    service.profile.value = service.profile.value.copyWith(repetitionMode: true);
    const wrapper = AdaptiveWrapper(screenTitle: 'EduBridge', child: SizedBox(width: 100, height: 100));
    await host(tester, 'ar', wrapper);
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
    calls.clear();
    await host(tester, 'en', wrapper);
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    expect(spoken(), 'EduBridge');
    calls.clear();
    service.profile.value = service.profile.value.copyWith(extraLargeTouchTargets: true);
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    calls.clear();
    await AdaptiveHelper.speak('نص قديم');
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
    expect(tester.takeException(), isNull);
  });
}
