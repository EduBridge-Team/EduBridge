import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/tts_service.dart';
import 'package:edubridge_app/widgets/accessibility/brain_break_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _host(WidgetTester tester, String language, AccessibilityProfile profile,
    {double scale = 1}) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale)), child: child!),
    home: Scaffold(body: Builder(builder: (context) => TextButton(
      onPressed: () => BrainBreakDialog.show(context, profile: profile), child: const Text('open'))))));
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}
const _profile = AccessibilityProfile(type: DisabilityType.none,
  brainBreakDurationSeconds: 60, reducedAnimations: true);
void main() {
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language break at $scale keeps suggestions, two extensions and early return', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final s = await AppLocalizations.delegate.load(Locale(language));
        await _host(tester, language, _profile, scale: scale);
        await _tap(tester, 'open');
        expect(find.text(s.breakTitle), findsOneWidget);
        expect(find.text(s.breakComfort), findsOneWidget);
        expect(Directionality.of(tester.element(find.byType(BrainBreakDialog))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
        await _tap(tester, s.breakAnother);
        expect(find.text(s.breakAskHelp), findsOneWidget);
        await _tap(tester, s.breakAnother);
        expect(find.text(s.breakAway), findsOneWidget);
        await _tap(tester, s.breakExtend);
        await _tap(tester, s.breakExtend);
        expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, s.breakExtensionLimit)).onPressed, isNull);
        await _tap(tester, s.breakReady);
        expect(find.byType(BrainBreakDialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('$language hidden countdown still ends at the specialist duration', (tester) async {
      await _host(tester, language, _profile.copyWith(noTimers: true));
      await _tap(tester, 'open');
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(BrainBreakDialog), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.byType(BrainBreakDialog), findsNothing);
    });
  }
  testWidgets('locale changes preserve the open break, suggestion and extensions', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await _host(tester, 'ar', _profile);
    await _tap(tester, 'open');
    await _tap(tester, ar.breakAnother);
    await _tap(tester, ar.breakExtend);
    await _tap(tester, ar.breakExtend);
    await _host(tester, 'en', _profile);
    expect(find.text(en.breakAskHelp), findsOneWidget);
    expect(find.text(en.breakExtensionLimit), findsOneWidget);
    await _tap(tester, en.breakReady);
    expect(find.byType(BrainBreakDialog), findsNothing);
  });
  testWidgets('English speech keeps digits and percentages; legacy speech remains Arabic', (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 1;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    Object? speechText() {
      final arguments = calls.lastWhere((c) => c.method == 'speak').arguments;
      return arguments is Map ? arguments['text'] : arguments;
    }
    await TtsService.instance.speakLine('30 seconds, 50%', languageCode: 'en');
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    expect(speechText(), '30 seconds, 50%');
    await TtsService.instance.speakLine('30%');
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
    expect(speechText(), '٣٠ بالمئة');
    await TtsService.instance.stop();
  });
}
