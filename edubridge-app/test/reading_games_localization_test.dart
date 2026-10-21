import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:edubridge_app/games/visual_words_game.dart';
import 'package:edubridge_app/games/advanced_reading_game.dart';
import 'package:edubridge_app/features/games/data/learning_question_bank.dart';
import 'package:edubridge_app/features/games/domain/quiz_question.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/utils/reading_game_display.dart';
import 'package:edubridge_app/utils/visual_word_display.dart';
import 'package:edubridge_app/widgets/accessibility/game_round_continuation.dart';
import 'package:edubridge_app/widgets/accessibility/game_stat_chip.dart';
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
void main() {
  test('all visual words and reading questions translate with shuffled answers intact', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final arabic = jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync()) as Map<String, dynamic>;
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final words = arabic.keys.where((key) => key.startsWith('visualWord') && !key.startsWith('visualWords')).toList();
    expect(words, hasLength(24));
    for (final key in words) {
      expect(VisualWordDisplay.word(arabic[key], ar), arabic[key]);
      expect(VisualWordDisplay.word(arabic[key], en), english[key]);
    }
    for (final original in LearningQuestionBank.reading) {
      final translated = ReadingGameDisplay.question(original, en);
      expect(translated.passage, isNot(contains(RegExp('[ء-ي]'))));
      expect(translated.prompt, isNot(contains(RegExp('[ء-ي]'))));
      for (var seed = 0; seed < 8; seed++) {
        final shuffled = original.shuffled(random: Random(seed));
        final result = ReadingGameDisplay.question(shuffled, en);
        expect(result.correctAnswerIndex, shuffled.correctAnswerIndex);
        expect(result.choices[result.correctAnswerIndex], translated.choices[original.correctAnswerIndex]);
        final arabicResult = ReadingGameDisplay.question(shuffled, ar);
        expect(arabicResult.choices, shuffled.choices);
        expect(arabicResult.prompt, shuffled.prompt);
        expect(arabicResult.passage, shuffled.passage);
      }
    }
    final custom = QuizQuestion(prompt: 'custom', passage: 'original', choices: ['a','b'], correctAnswerIndex: 1);
    expect(ReadingGameDisplay.question(custom, en), same(custom));
    expect(VisualWordDisplay.word('custom', en), 'custom');
  });
  testWidgets('visual words and reading preserve answers and speech through language changes at large text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      sensoryCalmMode: true, slowSpeech: true, noTimedInteractions: true);
    addTearDown(AccessibilityService.instance.resetSession);
    final speech = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { speech.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    for (final age in [5, 9]) {
      final game = VisualWordsGame(childName: 'ليان', age: age);
      await host(tester, 'en', game);
      final emoji = tester.widget<Text>(find.byKey(const ValueKey('visual_target'))).data!;
      final choices = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('visual_choice_'));
      expect(choices, findsNWidgets(age == 5 ? 3 : 4));
      final wrong = choices.evaluate().firstWhere((e) => e.widget.key != ValueKey('visual_choice_$emoji')).widget.key!;
      await tap(tester, find.byKey(wrong));
      expect(tester.widgetList<GameStatChip>(find.byType(GameStatChip)).firstWhere((c) => c.label == en.sequenceScore).value, '0');
      await tap(tester, find.byKey(ValueKey('visual_choice_$emoji')));
      await tap(tester, find.byKey(ValueKey('visual_choice_$emoji')));
      expect(tester.widgetList<GameStatChip>(find.byType(GameStatChip)).firstWhere((c) => c.label == en.sequenceScore).value, '1');
      await host(tester, 'ar', game);
      expect(tester.widget<Text>(find.byKey(const ValueKey('visual_target'))).data, emoji);
      expect(tester.widgetList<GameStatChip>(find.byType(GameStatChip)).firstWhere((c) => c.label == ar.sequenceScore).value, '1');
      await tap(tester, find.text(ar.feedbackContinue));
      expect(find.text('2/8'), findsOneWidget);
      expect(speech.where((c) => c.method == 'speak'), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    const game = AdvancedReadingGame(childName: 'ليان');
    await host(tester, 'en', game);
    final prompt = tester.widget<Text>(find.byKey(const ValueKey('reading_question'))).data;
    final original = LearningQuestionBank.reading.firstWhere((q) => ReadingGameDisplay.question(q, en).prompt == prompt);
    final translated = ReadingGameDisplay.question(original, en);
    final correctText = translated.choices[translated.correctAnswerIndex];
    final wrong = find.byType(OutlinedButton).evaluate().firstWhere((e) =>
      tester.widget<Text>(find.descendant(of: find.byKey(e.widget.key!), matching: find.byType(Text))).data != correctText).widget.key!;
    await tap(tester, find.byKey(wrong));
    expect(find.text(en.readingIncorrect), findsOneWidget);
    await host(tester, 'ar', game);
    expect(find.text(ar.readingIncorrect), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('reading_question'))).data, original.prompt);
    expect(tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)).every((b) => b.onPressed == null), isTrue);
    await tap(tester, find.text(ar.readingListen));
    expect(speech.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
    expect(speech.where((c) => c.method == 'setSpeechRate').last.arguments, 0.30);
    speech.clear();
    await host(tester, 'en', game);
    await tap(tester, find.text(en.readingListen));
    expect(speech.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    final args = speech.where((c) => c.method == 'speak').last.arguments;
    expect(args is Map ? args['text'] : args, translated.passage);
    await tap(tester, find.text(en.feedbackContinue));
    expect(find.text(en.readingIncorrect), findsNothing);
    final nextPrompt = tester.widget<Text>(find.byKey(const ValueKey('reading_question'))).data;
    final next = LearningQuestionBank.reading.map((q) => ReadingGameDisplay.question(q, en)).firstWhere((q) => q.prompt == nextPrompt);
    await tap(tester, find.text(next.choices[next.correctAnswerIndex]));
    expect(find.text(en.readingCorrect), findsOneWidget);
    await host(tester, 'ar', game);
    expect(find.text(ar.readingCorrect), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('continuation busy and failed states follow the selected language', (tester) async {
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, noTimedInteractions: true);
    addTearDown(AccessibilityService.instance.resetSession);
    final pending = Completer<void>();
    final game = Scaffold(body: GameRoundContinuation(answered: true, onContinue: () => pending.future));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await host(tester, 'en', game);
    await tap(tester, find.text(en.feedbackContinue));
    expect(find.text(en.gameRoundContinuing), findsOneWidget);
    await host(tester, 'ar', game);
    expect(find.text(ar.gameRoundContinuing), findsOneWidget);
    pending.completeError(StateError('retry'));
    await tester.pumpAndSettle();
    expect(find.text(ar.gameRoundContinueFailed), findsOneWidget);
    await host(tester, 'en', game);
    expect(find.text(en.gameRoundContinueFailed), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
