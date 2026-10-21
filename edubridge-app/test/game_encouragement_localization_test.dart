import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/app_locale_controller.dart';
import 'package:edubridge_app/services/encouragement_service.dart';
import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:edubridge_app/games/matching_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() { AccessibilityService.instance.resetSession(); GameProgressService.instance.end(); });
  for (final language in ['ar', 'en']) {
    test('$language encouragement keeps score boundaries, names and speech preferences', () async {
      final s = await AppLocalizations.delegate.load(Locale(language));
      var profile = const AccessibilityProfile(type: DisabilityType.none, autoReadOnTap: true);
      final normal = <String>[];
      final slow = <String>[];
      final service = EncouragementService(strings: () => s, profile: () => profile,
        speak: (text) async => normal.add(text), speakSlow: (text) async => slow.add(text));
      for (final score in [0, 49, 50, 69, 70, 89, 90, 100]) {
        await service.praiseScore(score);
        final expected = score >= 90 ? s.encourageScore1(score) : score >= 70
          ? s.encourageScore2(score) : score >= 50 ? s.encourageScore3(score) : s.encourageScore4(score);
        expect(normal.last, expected);
      }
      await service.praiseByName('محمود');
      expect(normal.last, contains('محمود'));
      expect([s.encourageNamed1('محمود'), s.encourageNamed2('محمود'),
        s.encourageNamed3('محمود'), s.encourageNamed4('محمود')], contains(normal.last));
      await service.praiseForDown(childName: 'محمود');
      expect(normal.last, startsWith('محمود'));
      profile = profile.copyWith(slowSpeech: true);
      await service.praiseSuccess();
      expect(slow, hasLength(1));
      profile = profile.copyWith(sensoryCalmMode: true);
      final count = normal.length;
      await service.praiseStart(); await service.praiseGame(); await service.gentleRetry(); await service.praiseStreak();
      expect(normal, hasLength(count)); expect(slow, hasLength(1));
      profile = profile.copyWith(sensoryCalmMode: false, autoReadOnTap: false);
      await service.praiseSuccess();
      expect(slow, hasLength(1));
    });
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language matching at $scale preserves authored cards and round results', (tester) async {
        tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
        addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
        AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, sensoryCalmMode: true);
        final s = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(MaterialApp(locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: const MatchingGame(childName: 'محمود', items: ['أ'])));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'initial board layout');
        expect(find.text(s.matchingTitle), findsOneWidget);
        final cards = find.byWidgetPredicate((w) => w is GestureDetector && w.child is AnimatedContainer);
        expect(cards, findsNWidgets(2));
        await tester.tap(cards.at(0)); await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('أ'), findsOneWidget);
        await tester.tap(cards.at(1)); await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 400)); await tester.pump();
        expect(find.text('أ'), findsNWidgets(2));
        await tester.pump(const Duration(seconds: 4)); await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'result dialog layout');
        expect(find.text(s.matchingWellDone), findsOneWidget);
        expect(find.text(s.matchingAttempts), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        await tester.tap(find.text(s.matchingPlayAgain)); await tester.pumpAndSettle();
        expect(find.text(s.matchingWellDone), findsNothing);
        expect(find.text('أ'), findsNothing);
        expect(cards, findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  test('shared encouragement resolves the current saved locale on every event', () async {
    final previous = AppLocaleController.instance.value;
    addTearDown(() => AppLocaleController.instance.value = previous);
    final words = <String>[];
    final service = EncouragementService(profile: () => const AccessibilityProfile(type: DisabilityType.none, autoReadOnTap: true),
      speak: (text) async => words.add(text));
    AppLocaleController.instance.value = const Locale('ar'); await service.praiseGame();
    expect(words.last, matches(RegExp('[ء-ي]')));
    AppLocaleController.instance.value = const Locale('en'); await service.praiseGame();
    expect(words.last.contains(RegExp('[ء-ي]')), isFalse);
  });
  testWidgets('English encouragement selects the English device voice', (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { calls.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final s = await AppLocalizations.delegate.load(const Locale('en'));
    final service = EncouragementService(strings: () => s,
      profile: () => const AccessibilityProfile(type: DisabilityType.none, autoReadOnTap: true, slowSpeech: true));
    await service.praiseScore(90);
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    final args = calls.lastWhere((c) => c.method == 'speak').arguments;
    expect(args is Map ? args['text'] : args, s.encourageScore1(90));
  });
}
