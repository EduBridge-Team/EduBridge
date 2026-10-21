import 'package:edubridge_app/games/symbols_game.dart';
import 'package:edubridge_app/games/sign_language_game.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:edubridge_app/utils/symbol_sign_display.dart';
import 'package:edubridge_app/widgets/accessibility/game_stat_chip.dart';
import 'package:edubridge_app/widgets/accessibility/visual_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> host(WidgetTester tester, String language, Widget game) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(2)), child: child!), home: game));
  await tester.pumpAndSettle();
}
Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target); await tester.tap(target); await tester.pumpAndSettle();
}
Finder choices(String prefix) => find.byWidgetPredicate((w) => w is GestureDetector &&
  w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix));
void main() {
  test('all symbol names and gesture descriptions translate while custom values remain original', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    for (final name in ['مثلث','دائرة','مربع','نجمة','معين','قلب']) {
      expect(SymbolSignDisplay.symbol(name, ar), name);
      expect(SymbolSignDisplay.symbol(name, en), isNot(contains(RegExp('[ء-ي]'))));
    }
    for (final description in ['إصبع الإبهام مرفوع','كف مفتوح مستقيم','إصبعان مفتوحان','ثلاثة أصابع','قبضة مغلقة','الإبهام والخنصر','إصبعان متقاطعان','إصبع واحد مرفوع']) {
      expect(SymbolSignDisplay.sign(description, ar), description);
      expect(SymbolSignDisplay.sign(description, en), isNot(contains(RegExp('[ء-ي]'))));
    }
    expect(SymbolSignDisplay.symbol('custom', en), 'custom');
    expect(SymbolSignDisplay.sign('custom', en), 'custom');
  });
  testWidgets('symbols and sign matching preserve answers, scores, speech and replay across languages', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GameProgressService.instance.end();
    final service = AccessibilityService.instance;
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      noTimedInteractions: true, autoReadOnTap: true, slowSpeech: true);
    addTearDown(service.resetSession);
    final speech = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { speech.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    const symbols = SymbolsGame(childName: 'ليان');
    await host(tester, 'en', symbols);
    expect(speech.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    expect(speech.where((c) => c.method == 'setSpeechRate').last.arguments, 0.30);
    final symbol = tester.widget<Text>(find.byKey(const ValueKey('symbols_target'))).data!;
    final keys = tester.widgetList<GestureDetector>(choices('symbols_choice_')).map((w) => w.key!).toList();
    expect(keys, hasLength(4));
    final wrong = keys.firstWhere((key) => key != ValueKey('symbols_choice_$symbol'));
    await tap(tester, find.byKey(wrong));
    expect(tester.widgetList<GameStatChip>(find.byType(GameStatChip)).firstWhere((c) => c.label == en.sequenceScore).value, '0');
    await tap(tester, find.byKey(ValueKey('symbols_choice_$symbol')));
    await tap(tester, find.byKey(ValueKey('symbols_choice_$symbol')));
    expect(tester.widgetList<GameStatChip>(find.byType(GameStatChip)).firstWhere((c) => c.label == en.sequenceScore).value, '1');
    await host(tester, 'ar', symbols);
    expect(tester.widgetList<GestureDetector>(choices('symbols_choice_')).map((w) => w.key), keys);
    expect(tester.widget<Text>(find.byKey(const ValueKey('symbols_target'))).data, symbol);
    expect(speech.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
    service.profile.value = service.profile.value.copyWith(sensoryCalmMode: true);
    speech.clear();
    await tap(tester, find.text(ar.feedbackContinue));
    expect(find.text('2/8'), findsOneWidget);
    expect(speech.where((c) => c.method == 'speak'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    const sign = SignLanguageGame(childName: 'ليان');
    await host(tester, 'en', sign);
    expect(find.text(en.signInstruction), findsOneWidget);
    for (var round = 1; round <= 8; round++) {
      final letter = tester.widget<Text>(find.byKey(const ValueKey('sign_target'))).data!;
      expect(letter, contains(RegExp('[ء-ي]')));
      expect(choices('sign_choice_'), findsNWidgets(4));
      final wrong = tester.widgetList<GestureDetector>(choices('sign_choice_')).firstWhere((w) => w.key != ValueKey('sign_choice_$letter'));
      await tap(tester, find.byKey(wrong.key!));
      expect(find.text(en.orderedGameScore(round - 1)), findsOneWidget);
      await tap(tester, find.byKey(ValueKey('sign_choice_$letter')));
      await tap(tester, find.byKey(ValueKey('sign_choice_$letter')));
      expect(find.text(en.orderedGameScore(round)), findsOneWidget);
      await host(tester, 'ar', sign);
      expect(tester.widget<Text>(find.byKey(const ValueKey('sign_target'))).data, letter);
      expect(find.text(ar.orderedGameScore(round)), findsOneWidget);
      await host(tester, 'en', sign);
      await tap(tester, find.text(en.feedbackContinue));
    }
    final overlay = find.byType(VisualCelebration);
    expect(overlay, findsOneWidget);
    await tap(tester, find.descendant(of: overlay, matching: find.text(en.feedbackContinue)));
    expect(find.text(en.signChampion), findsOneWidget);
    expect(find.text(en.signResult(8, 8)), findsOneWidget);
    await host(tester, 'ar', sign);
    expect(find.text(ar.signChampion), findsOneWidget);
    expect(find.text(ar.signPercentage(100)), findsOneWidget);
    await tap(tester, find.text(ar.choiceReplay));
    expect(find.text(ar.orderedGameScore(0)), findsOneWidget);
    expect(find.text(ar.orderedGameRound(1, 8)), findsOneWidget);
    expect(speech.where((c) => c.method == 'speak'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
