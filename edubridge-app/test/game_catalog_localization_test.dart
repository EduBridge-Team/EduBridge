import 'dart:async';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/utils/game_catalog.dart';
import 'package:edubridge_app/utils/game_catalog_display.dart';
import 'package:edubridge_app/screens/educational_games_screen.dart';
import 'package:edubridge_app/games/matching_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/encouragement_service.dart';
import 'package:edubridge_app/widgets/accessibility/simple_icons_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Observer extends NavigatorObserver {
  final opened = Completer<void>();
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && !opened.isCompleted) opened.complete();
  }
}
Future<void> _host(WidgetTester tester, String language, Widget child,
    {double scale = 1, NavigatorObserver? observer}) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    navigatorObservers: observer == null ? [] : [observer],
    builder: (context, body) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: body!),
    home: child));
  await tester.pumpAndSettle();
}
void main() {
  setUp(() {
    AccessibilityService.instance.resetSession();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(AccessibilityService.instance.resetSession);
  test('all catalog entries translate while eligibility and custom values remain original', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    for (final game in kGameCatalog) {
      expect(GameCatalogDisplay.title(game, ar), game.title);
      expect(GameCatalogDisplay.description(game, ar), game.description);
      expect(GameCatalogDisplay.title(game, en).contains(RegExp('[ء-ي]')), isFalse);
      expect(GameCatalogDisplay.description(game, en).contains(RegExp('[ء-ي]')), isFalse);
    }
    const custom = GameInfo(id: 'custom', title: 'عنوان أصلي', description: 'وصف أصلي', emoji: '', ages: []);
    expect(GameCatalogDisplay.title(custom, en), custom.title);
    expect(GameCatalogDisplay.description(custom, en), custom.description);
    for (final age in AgeGroup.values) {
      expect(GameCatalogDisplay.age(age, ar), ageGroupLabel(age));
      for (final type in DisabilityType.values) {
        final before = gamesFor(type, age).map((g) => g.id).toList();
        for (final game in gamesFor(type, age)) {
          GameCatalogDisplay.title(game, en); GameCatalogDisplay.description(game, en);
        }
        expect(gamesFor(type, age).map((g) => g.id), before);
      }
    }
    expect(en.gameCatalogCount(1, 'Primary'), '1 game for your age (Primary)');
    expect(en.gameCatalogCount(2, 'Primary'), '2 games for your age (Primary)');
  });
  for (final language in ['ar', 'en']) {
    for (final simple in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$language catalog simple=$simple scale=$scale keeps age and disability filtering', (tester) async {
          tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
          addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
          final type = simple ? DisabilityType.blind : DisabilityType.none;
          AccessibilityService.instance.profile.value = AccessibilityProfile(type: type, simpleIconsGrid: simple);
          final s = await AppLocalizations.delegate.load(Locale(language));
          for (final age in [5, 8, 13]) {
            await _host(tester, language, EducationalGamesScreen(childName: 'محمود', age: age), scale: scale);
            final games = gamesFor(type, ageGroupOf(age));
            expect(find.text(s.gameCatalogTitle), findsOneWidget);
            expect(find.text(s.gameCatalogCount(games.length, GameCatalogDisplay.age(ageGroupOf(age), s))), findsOneWidget);
            for (final game in games) {
              expect(find.text(GameCatalogDisplay.title(game, s)), findsOneWidget);
              if (!simple) expect(find.text(GameCatalogDisplay.description(game, s)), findsOneWidget);
              if (simple) expect(find.byKey(ValueKey('simple_game_${game.id}')), findsOneWidget);
            }
            for (final game in kGameCatalog.where((g) => !games.contains(g))) {
              expect(find.text(GameCatalogDisplay.title(game, s)), findsNothing);
            }
            if (!simple) expect(find.byIcon(language == 'ar' ? Icons.chevron_left : Icons.chevron_right), findsNWidgets(games.length));
            expect(tester.takeException(), isNull);
          }
        });
      }
      testWidgets('$language simple=$simple opens the canonical matching game and preserves the player', (tester) async {
        AccessibilityService.instance.profile.value = AccessibilityProfile(type: DisabilityType.none, simpleIconsGrid: simple);
        final s = await AppLocalizations.delegate.load(Locale(language));
        final observer = _Observer();
        await _host(tester, language, const EducationalGamesScreen(childName: 'محمود', age: 5), observer: observer);
        final target = find.text(s.gameCatalogMatchingTitle);
        await Scrollable.ensureVisible(tester.element(target), alignment: .5); await tester.pumpAndSettle();
        await tester.tap(target.hitTestable());
        await tester.runAsync(() => observer.opened.future.timeout(const Duration(seconds: 5)));
        await tester.pumpAndSettle();
        expect(find.byType(MatchingGame), findsOneWidget);
        expect(tester.widget<MatchingGame>(find.byType(MatchingGame)).childName, 'محمود');
        Navigator.of(tester.element(find.byType(MatchingGame))).pop(); await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('language changes update the catalog without replaying its welcome', (tester) async {
    var welcomes = 0;
    final service = EncouragementService(profile: () => const AccessibilityProfile(type: DisabilityType.none, autoReadOnTap: true),
      speak: (_) async { welcomes++; });
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.deaf);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await _host(tester, 'ar', EducationalGamesScreen(childName: 'محمود', encouragement: service));
    await _host(tester, 'en', EducationalGamesScreen(childName: 'محمود', encouragement: service));
    expect(welcomes, 1);
    expect(find.text(en.gameCatalogHeroWelcome), findsOneWidget);
    expect(find.text(en.gameCatalogSignLanguageTitle), findsOneWidget);
  });
  testWidgets('simple catalog tiles use the requested speech language and keep tap callbacks', (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { calls.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, autoReadOnTap: true);
    var taps = 0;
    await _host(tester, 'en', Scaffold(body: SimpleIconsGrid(children: [SimpleIconTile(
      title: 'Matching', icon: Icons.style, speechLanguageCode: 'en', onTap: () => taps++)])));
    await tester.tap(find.text('Matching'));
    await tester.runAsync(() async { await Future<void>.delayed(Duration.zero); });
    expect(taps, 1);
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    final args = calls.lastWhere((c) => c.method == 'speak').arguments;
    expect(args is Map ? args['text'] : args, 'Matching');
  });
}
