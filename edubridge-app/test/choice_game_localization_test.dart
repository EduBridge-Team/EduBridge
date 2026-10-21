import 'package:edubridge_app/games/choice_learning_game.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:edubridge_app/utils/choice_game_display.dart';
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
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
Finder options() => find.byWidgetPredicate((w) => w is OutlinedButton &&
  w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('choice_option_'));
int target(WidgetTester tester, LearningTopic topic, AppLocalizations s) {
  if (topic == LearningTopic.numbers) {
    return find.descendant(of: find.byKey(const ValueKey('choice_count')), matching: find.byType(Text)).evaluate().length - 1;
  }
  final question = tester.widget<Text>(find.byKey(const ValueKey('choice_question'))).data;
  return List.generate(topic == LearningTopic.colors ? 10 : 9, (i) => i).firstWhere((i) => question ==
    s.choiceWhere(topic == LearningTopic.colors ? ChoiceGameDisplay.color(i, s) : ChoiceGameDisplay.shape(i, s)));
}
void main() {
  test('all color, shape, number and counting presentations support both languages', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    for (var i = 0; i < 10; i++) {
      expect(ChoiceGameDisplay.color(i, ar), contains(RegExp('[ء-ي]')));
      expect(ChoiceGameDisplay.color(i, en), isNot(contains(RegExp('[ء-ي]'))));
      expect(ChoiceGameDisplay.number(i, en), '${i + 1}');
      expect(ChoiceGameDisplay.number(i, ar), ['١','٢','٣','٤','٥','٦','٧','٨','٩','١٠'][i]);
      if (i < 9) {
        expect(ChoiceGameDisplay.shape(i, en), isNot(contains(RegExp('[ء-ي]'))));
        expect(ChoiceGameDisplay.shapeHint(i, en), isNot(contains(RegExp('[ء-ي]'))));
        expect(ChoiceGameDisplay.shapeHint(i, ar), contains(RegExp('[ء-ي]')));
      }
    }
    for (final emoji in ['🍎','⭐','⚽','🌸','🐟','🦋']) {
      expect(ChoiceGameDisplay.question(emoji, en), isNot(contains(RegExp('[ء-ي]'))));
      expect(ChoiceGameDisplay.hint(emoji, en, '1, 2'), contains('1, 2'));
      for (final count in [1, 2, 10]) {
        expect(ChoiceGameDisplay.count(emoji, en, count), startsWith('$count '));
      }
    }
    expect(ChoiceGameDisplay.count('🍎', en, 1), '1 apple');
    expect(ChoiceGameDisplay.count('🍎', en, 2), '2 apples');
  });
  testWidgets('all topics preserve rounds, hints, wrong attempts, speech and summaries across locales', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GameProgressService.instance.end();
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      sensoryCalmMode: true, slowSpeech: true, noTimedInteractions: true);
    addTearDown(AccessibilityService.instance.resetSession);
    final speech = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { speech.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    for (final language in ['ar','en']) {
      final s = await AppLocalizations.delegate.load(Locale(language));
      final other = await AppLocalizations.delegate.load(Locale(language == 'ar' ? 'en' : 'ar'));
      for (final topic in LearningTopic.values) {
        final game = ChoiceLearningGame(topic: topic, childName: 'ليان', age: 5);
        await host(tester, language, game);
        expect(find.text(s.choiceWelcome('ليان')), findsOneWidget);
        speech.clear();
        await tap(tester, find.text(s.choiceStart));
        expect(speech.where((c) => c.method == 'speak'), isEmpty);
        expect(options(), findsNWidgets(3));
        final initial = target(tester, topic, s);
        final wrong = tester.widgetList<OutlinedButton>(options()).firstWhere((w) => w.key != ValueKey('choice_option_$initial'));
        await tap(tester, find.byKey(wrong.key!));
        expect(find.text(s.choiceRetry), findsOneWidget);
        await host(tester, other.localeName, game);
        expect(find.text(other.choiceRetry), findsOneWidget);
        expect(target(tester, topic, other), initial);
        expect(tester.widget<OutlinedButton>(find.byKey(wrong.key!)).onPressed, isNull);
        await tap(tester, find.text(other.choiceHint));
        await host(tester, language, game);
        expect(target(tester, topic, s), initial);
        expect(find.text(s.choiceRetry), findsNothing);
        await tap(tester, find.text(s.choiceListen));
        expect(speech.where((c) => c.method == 'setLanguage').last.arguments, language);
        expect(speech.where((c) => c.method == 'setSpeechRate').last.arguments, 0.30);
        speech.clear();
        await tap(tester, find.text(s.choiceSound));
        await tap(tester, find.text(s.choiceListen));
        expect(speech.where((c) => c.method == 'speak'), isEmpty);
        for (var round = 0; round < 6; round++) {
          final answer = target(tester, topic, s);
          await tap(tester, find.byKey(ValueKey('choice_option_$answer')));
          if (round < 5) {
            expect(find.text(s.choiceNext), findsOneWidget);
            expect(find.byIcon(language == 'ar' ? Icons.arrow_back : Icons.arrow_forward), findsWidgets);
            await tap(tester, find.text(s.choiceNext));
          }
        }
        expect(find.text(s.choiceCompleted), findsOneWidget);
        expect(find.text(s.choiceSummary(6, 5)), findsOneWidget);
        await host(tester, other.localeName, game);
        expect(find.text(other.choiceSummary(6, 5)), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
