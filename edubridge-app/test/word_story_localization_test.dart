import 'dart:convert';
import 'dart:io';
import 'package:edubridge_app/games/word_builder_game.dart';
import 'package:edubridge_app/games/story_sequencer_game.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/utils/ordered_game_display.dart';
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
Finder cards(String prefix) => find.byWidgetPredicate((w) => w is GestureDetector &&
  w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix));
Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
void main() {
  test('all 36 words and 40 story values translate without changing canonical IDs', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final original = jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync()) as Map<String, dynamic>;
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    for (final prefix in ['wordItem', 'storyItem']) {
      final keys = original.keys.where((k) => k.startsWith(prefix)).toList();
      expect(keys.length, prefix == 'wordItem' ? 36 : 40);
      for (final key in keys) {
        final canonical = original[key] as String;
        final display = prefix == 'wordItem' ? OrderedGameDisplay.word : OrderedGameDisplay.story;
        expect(display(canonical, ar), canonical);
        expect(display(canonical, en), english[key]);
        expect(display(canonical, en), isNot(contains(RegExp('[ء-ي]'))));
      }
    }
    expect(OrderedGameDisplay.word('custom', en), 'custom');
    expect(OrderedGameDisplay.story('custom', en), 'custom');
  });
  testWidgets('ordered games retain scoring, retry, speech and age rules across locales at large text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final speech = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { speech.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      noTimedInteractions: true, autoReadOnTap: false);
    addTearDown(AccessibilityService.instance.resetSession);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    for (final age in [7, 10, 13]) {
      final game = WordBuilderGame(childName: 'ليان', age: age);
      await host(tester, 'en', game);
      final prefix = en.wordBuilderTarget('');
      String target() => tester.widget<Text>(find.byWidgetPredicate((w) => w is Text && (w.data?.startsWith(prefix) ?? false))).data!.substring(prefix.length);
      final word = target();
      expect(word, isNot(contains(RegExp('[ء-ي]'))));
      expect(cards('word_choice_'), findsNWidgets(word.length));
      // Every generated initial order differs from the solution.
      final wrongKeys = tester.widgetList<GestureDetector>(cards('word_choice_')).map((w) => w.key!).toList();
      for (final key in wrongKeys) { await tap(tester, find.byKey(key)); }
      expect(find.text(en.wordBuilderIncorrect), findsOneWidget);
      await tap(tester, find.text(en.retry));
      expect(find.text(en.wordBuilderIncorrect), findsNothing);
      final remaining = tester.widgetList<GestureDetector>(cards('word_choice_')).map((w) {
        final letter = tester.widget<Text>(find.descendant(of: find.byKey(w.key!), matching: find.byType(Text))).data!;
        return (w.key!, letter);
      }).toList();
      for (final letter in word.split('')) {
        final index = remaining.indexWhere((item) => item.$2 == letter);
        expect(index, greaterThanOrEqualTo(0));
        await tap(tester, find.byKey(remaining.removeAt(index).$1));
      }
      expect(find.text(en.sequenceCorrect), findsOneWidget);
      expect(find.text(en.orderedGameScore(1)), findsOneWidget);
      await host(tester, 'ar', game);
      expect(find.text(ar.sequenceCorrect), findsOneWidget);
      expect(find.text(ar.orderedGameScore(1)), findsOneWidget);
      expect(find.text(ar.orderedGameRound(1, 6)), findsOneWidget);
      await host(tester, 'en', game);
      expect(target(), word);
      expect(find.text(en.orderedGameScore(1)), findsOneWidget);
      speech.clear();
      await tap(tester, find.text(en.wordBuilderListen));
      await tester.runAsync(() async { await Future<void>.delayed(Duration.zero); });
      expect(speech.where((c) => c.method == 'setLanguage').last.arguments, 'en');
      final args = speech.where((c) => c.method == 'speak').last.arguments;
      expect(args is Map ? args['text'] : args, word);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    for (final age in [7, 10]) {
      final game = StorySequencerGame(childName: 'ليان', age: age);
      await host(tester, 'en', game);
      expect(find.text(en.storyGameTitle), findsOneWidget);
      final keys = tester.widgetList<GestureDetector>(cards('story_choice_')).map((w) => w.key!).toList();
      expect(keys.length, age == 7 ? 3 : 4);
      expect(find.text(age == 7 ? '1/4' : '1/6'), findsOneWidget);
      for (final key in keys) { await tap(tester, find.byKey(key)); }
      expect(find.text(en.sequenceIncorrect), findsOneWidget);
      await host(tester, 'ar', game);
      expect(find.text(ar.sequenceIncorrect), findsOneWidget);
      expect(tester.widgetList<GestureDetector>(cards('story_choice_')).map((w) => w.key), keys);
      await tap(tester, find.text(ar.retry));
      expect(find.text(ar.sequenceIncorrect), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
