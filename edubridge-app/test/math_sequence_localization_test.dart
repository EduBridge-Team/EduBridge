import 'package:edubridge_app/games/math_race_game.dart';
import 'package:edubridge_app/games/sequence_game.dart';
import 'package:edubridge_app/games/game_content.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
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
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccessibilityService.instance.resetSession();
  });
  tearDown(AccessibilityService.instance.resetSession);
  testWidgets('math and sequencing retain behavior across locales at large text scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final language in ['ar', 'en']) {
      final s = await AppLocalizations.delegate.load(Locale(language));
      await host(tester, language, const MathRaceGame(childName: 'ليان', age: 9));
      expect(find.text(s.mathRaceTitle), findsOneWidget);
      expect(find.text(s.mathFinish), findsOneWidget);
      final expression = tester.widget<Text>(find.byWidgetPredicate((w) => w is Text && (w.data?.endsWith('= ?') ?? false)));
      expect(expression.textDirection, TextDirection.ltr);
      expect(find.byType(ElevatedButton), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());

    // GameContent retains its write future; exercise both games in one test zone.
    const game = SequenceGame(childName: 'ليان');
    await host(tester, 'en', game);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final choices = find.byWidgetPredicate((w) => w is GestureDetector && w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('sequence_choice_'));
    final keys = tester.widgetList<GestureDetector>(choices).map((w) => w.key).toList();
    expect(keys, hasLength(3));
    for (final key in keys) {
      await tester.ensureVisible(find.byKey(key!));
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }
    final correct = find.text(en.sequenceCorrect).evaluate().isNotEmpty;
    expect(find.text(correct ? en.sequenceCorrect : en.sequenceIncorrect), findsOneWidget);
    await host(tester, 'ar', game);
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(ar.sequenceTitle), findsOneWidget);
    expect(find.text(correct ? ar.sequenceCorrect : ar.sequenceIncorrect), findsOneWidget);
    expect(tester.widgetList<GestureDetector>(choices).map((w) => w.key), keys);
    if (!correct) {
      await tester.ensureVisible(find.text(ar.retry));
      await tester.tap(find.text(ar.retry));
      await tester.pumpAndSettle();
      expect(find.text(ar.sequenceIncorrect), findsNothing);
    }
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async { await GameContent.instance.settled; });
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
