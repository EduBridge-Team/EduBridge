import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/games/audio_matching_game.dart';
import 'package:edubridge_app/games/quick_action_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _host(WidgetTester tester, String language, Widget child, double scale) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language), supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, body) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: body!), home: child));
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(target.hitTestable()); await tester.pump();
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
void main() {
  final calls = <MethodCall>[];
  const channel = MethodChannel('flutter_tts');
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { calls.add(call); return 1; });
    AccessibilityService.instance.resetSession();
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, sensoryCalmMode: true);
  });
  tearDown(() {
    AccessibilityService.instance.resetSession(); GameProgressService.instance.end();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language sound cards at $scale localize explicit listening without enabling automatic speech', (tester) async {
        tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
        addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
        final s = await AppLocalizations.delegate.load(Locale(language));
        await _host(tester, language, const AudioMatchingGame(childName: 'محمود'), scale);
        expect(find.text(s.audioGameTitle), findsOneWidget);
        expect(find.text(s.audioGameInstructions), findsOneWidget);
        expect(calls.where((c) => c.method == 'speak'), isEmpty);
        final names = [s.audioWordDog, s.audioWordCat, s.audioWordBird, s.audioWordCow,
          s.audioWordFrog, s.audioWordLion, s.audioWordElephant, s.audioWordHorse,
          s.audioWordCar, s.audioWordBicycle, s.audioWordApple, s.audioWordBanana];
        final cards = find.byWidgetPredicate((w) => w is Semantics && names.any((n) => w.properties.label == s.audioGameCard(n)));
        final first = tester.widget<Semantics>(cards.first).properties.label!;
        final expectedName = names.firstWhere((n) => s.audioGameCard(n) == first);
        final target = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == first).first;
        await _tap(tester, target);
        expect(calls.where((c) => c.method == 'setLanguage').last.arguments, language);
        final speech = calls.lastWhere((c) => c.method == 'speak').arguments;
        expect(speech is Map ? speech['text'] : speech, expectedName);
        await _tap(tester, target);
        expect(find.text(s.audioGameComplete), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
      testWidgets('$language quick actions at $scale preserve untimed play and pause/resume', (tester) async {
        tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
        addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
        AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, noTimers: true, sensoryCalmMode: true);
        final s = await AppLocalizations.delegate.load(Locale(language));
        await _host(tester, language, const QuickActionGame(childName: 'محمود'), scale);
        expect(find.text(s.actionTitle), findsOneWidget);
        expect(find.text(s.actionUntimed), findsOneWidget);
        await tester.pump(const Duration(seconds: 35));
        await _tap(tester, find.text(s.actionDone));
        expect(find.text('1'), findsNWidgets(2));
        await tester.tap(find.byTooltip(s.actionPause)); await tester.pumpAndSettle();
        expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, s.actionDone)).onPressed, isNull);
        await tester.tap(find.byTooltip(s.timerResume)); await tester.pumpAndSettle();
        await _tap(tester, find.text(s.actionDone));
        expect(find.text('2'), findsNWidgets(2));
        expect(calls.where((c) => c.method == 'speak'), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    testWidgets('$language quick-action deadline pauses and resumes without resetting', (tester) async {
      final s = await AppLocalizations.delegate.load(Locale(language));
      await _host(tester, language, const QuickActionGame(childName: 'محمود'), 1);
      await tester.tap(find.byTooltip(s.actionPause)); await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('30'), findsOneWidget);
      await tester.tap(find.byTooltip(s.timerResume)); await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('29'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
