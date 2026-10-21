import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:edubridge_app/games/logic_puzzle_game.dart';
import 'package:edubridge_app/games/rhythm_game.dart';
import 'package:edubridge_app/features/games/data/learning_question_bank.dart';
import 'package:edubridge_app/features/games/domain/quiz_question.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/utils/logic_game_display.dart';
import 'package:edubridge_app/utils/rhythm_word_display.dart';
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
  test('all 105 logic questions retain shuffled answers and all 12 rhythm words translate', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(LearningQuestionBank.logic, hasLength(105));
    for (final original in LearningQuestionBank.logic) {
      final translated = LogicGameDisplay.question(original, en);
      expect(translated.prompt, isNot(contains(RegExp('[ء-ي]'))));
      for (final choice in translated.choices) { expect(choice, isNot(contains(RegExp('[ء-ي]')))); }
      for (var seed = 0; seed < 6; seed++) {
        final shuffled = original.shuffled(random: Random(seed));
        final result = LogicGameDisplay.question(shuffled, en);
        expect(result.correctAnswerIndex, shuffled.correctAnswerIndex);
        expect(result.choices[result.correctAnswerIndex], translated.choices[original.correctAnswerIndex]);
        final arabic = LogicGameDisplay.question(shuffled, ar);
        expect(arabic.prompt, original.prompt);
        expect(arabic.choices, shuffled.choices);
      }
    }
    final arabic = jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync()) as Map<String, dynamic>;
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = arabic.keys.where((key) => key.startsWith('rhythmWord')).toList();
    expect(keys, hasLength(12));
    for (final key in keys) {
      expect(RhythmWordDisplay.word(arabic[key], ar), arabic[key]);
      expect(RhythmWordDisplay.word(arabic[key], en), english[key]);
    }
    final custom = QuizQuestion(prompt: 'custom', choices: ['a','b'], correctAnswerIndex: 0);
    expect(LogicGameDisplay.question(custom, en), same(custom));
  });
  testWidgets('logic and rhythm retain progress, speech and pause rules across languages with large text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = AccessibilityService.instance;
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      sensoryCalmMode: true, noTimedInteractions: true, slowSpeech: true);
    addTearDown(service.resetSession);
    final speech = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { speech.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    const logic = LogicPuzzleGame(childName: 'ليان');
    await host(tester, 'en', logic);
    for (var round = 0; round < 5; round++) {
      final prompt = tester.widget<Text>(find.byKey(const ValueKey('logic_question'))).data;
      final original = LearningQuestionBank.logic.firstWhere((q) => LogicGameDisplay.question(q, en).prompt == prompt);
      final translated = LogicGameDisplay.question(original, en);
      final correct = translated.choices[translated.correctAnswerIndex];
      final choice = round == 0 ? translated.choices.firstWhere((c) => c != correct) : correct;
      await tap(tester, find.text(choice));
      expect(find.text(round == 0 ? en.logicIncorrect : en.logicCorrect), findsOneWidget);
      expect(find.text(en.logicScore(round)), findsOneWidget);
      await host(tester, 'ar', logic);
      expect(find.text(original.prompt), findsOneWidget);
      expect(find.text(round == 0 ? ar.logicIncorrect : ar.logicCorrect), findsOneWidget);
      expect(tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).every((w) => w.onPressed == null), isTrue);
      await host(tester, 'en', logic);
      if (round < 4) { await tap(tester, find.text(en.feedbackContinue)); }
    }
    expect(speech.where((c) => c.method == 'speak'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    const rhythm = RhythmGame(childName: 'ليان');
    await host(tester, 'en', rhythm);
    expect(find.text(en.rhythmStepContinue), findsOneWidget);
    await tap(tester, find.text(en.rhythmStart));
    final englishWord = tester.widget<Text>(find.byKey(const ValueKey('rhythm_word'))).data!;
    await tap(tester, find.text(en.rhythmTap));
    await tap(tester, find.text(en.rhythmTap));
    expect(find.text('✓ 2'), findsOneWidget);
    await tap(tester, find.byTooltip(en.rhythmPause));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text(en.rhythmPosition(1, 8)), findsOneWidget);
    await host(tester, 'ar', rhythm);
    expect(find.text(ar.rhythmPaused), findsOneWidget);
    expect(find.text('✓ 2'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('rhythm_word'))).data, isNot(englishWord));
    await tap(tester, find.byTooltip(ar.feedbackContinue));
    await tap(tester, find.text(ar.wordBuilderListen));
    expect(speech.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
    expect(speech.where((c) => c.method == 'setSpeechRate').last.arguments, 0.30);
    speech.clear();
    await host(tester, 'en', rhythm);
    expect(tester.widget<Text>(find.byKey(const ValueKey('rhythm_word'))).data, englishWord);
    await tap(tester, find.text(en.wordBuilderListen));
    expect(speech.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    final args = speech.where((c) => c.method == 'speak').last.arguments;
    expect(args is Map ? args['text'] : args, englishWord);
    for (var index = 2; index <= 8; index++) {
      await tap(tester, find.text(en.feedbackContinue));
      expect(find.text(en.rhythmPosition(index, 8)), findsOneWidget);
    }
    await tap(tester, find.byTooltip(en.rhythmRestart));
    expect(find.text(en.rhythmPosition(1, 8)), findsOneWidget);
    expect(find.text('✓ 2'), findsNothing);
    service.profile.value = service.profile.value.copyWith(noTimedInteractions: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text(en.rhythmPosition(2, 8)), findsOneWidget);
    await tap(tester, find.byTooltip(en.rhythmPause));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text(en.rhythmPosition(2, 8)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
