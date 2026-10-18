import 'package:edubridge_app/games/sign_language_game.dart';
import 'package:edubridge_app/games/symbols_game.dart';
import 'package:edubridge_app/games/visual_words_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _words = {
  '🍎': 'تفاحة', '🐶': 'كلب', '🏠': 'بيت', '☀️': 'شمس', '🌙': 'قمر',
  '🚗': 'سيارة', '🌳': 'شجرة', '🐟': 'سمكة', '📚': 'كتاب', '✏️': 'قلم',
  '🧸': 'دبدوب', '🚲': 'دراجة', '🍌': 'موز', '🍇': 'عنب', '🌸': 'زهرة',
  '🐘': 'فيل', '🐢': 'سلحفاة', '🦋': 'فراشة', '✈️': 'طائرة', '🚂': 'قطار',
  '⚽': 'كرة', '🔑': 'مفتاح', '⏰': 'ساعة', '🥕': 'جزر',
};
const _signs = {
  'أ': 'إصبع الإبهام مرفوع', 'ب': 'كف مفتوح مستقيم',
  'ت': 'إصبعان مفتوحان', 'ث': 'ثلاثة أصابع', 'ج': 'قبضة مغلقة',
  'ح': 'الإبهام والخنصر', 'خ': 'إصبعان متقاطعان', 'د': 'إصبع واحد مرفوع',
};

Widget _game(String game) => switch (game) {
  'symbols' => const SymbolsGame(childName: 'نور'),
  'words' => const VisualWordsGame(childName: 'نور'),
  'young words' => const VisualWordsGame(childName: 'نور', age: 5),
  _ => const SignLanguageGame(childName: 'نور'),
};

Finder _round(String game, int number) => find.text(
  game == 'sign' ? 'الجولة: $number/8' : '$number/8');

Finder _answer(WidgetTester tester, String game) {
  final target = tester.widget<Text>(find.byWidgetPredicate((widget) =>
    widget is Text && switch (game) {
      'symbols' => widget.style?.fontSize == 85 || widget.style?.fontSize == 100,
      'sign' => widget.style?.fontSize == 90,
      _ => widget.style?.fontSize == 115 || widget.style?.fontSize == 130,
    }));
  return find.text(switch (game) {
    'symbols' => target.data!,
    'sign' => _signs[target.data]!,
    _ => _words[target.data]!,
  }).last;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  final service = AccessibilityService.instance;
  setUp(() {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      sensoryCalmMode: true);
  });
  tearDown(service.resetSession);

  for (final game in ['symbols', 'words', 'young words', 'sign']) {
    testWidgets('$game waits for Continue when timed interaction is disabled', (tester) async {
      service.profile.value = service.profile.value.copyWith(noTimedInteractions: true);
      await tester.pumpWidget(MaterialApp(home: _game(game)));
      final answer = _answer(tester, game);
      await _tapVisible(tester, answer);
      await _tapVisible(tester, answer);
      await tester.pump(const Duration(seconds: 10));
      expect(_round(game, 1), findsOneWidget);
      expect(find.text(game == 'sign' ? 'النقاط: 1 ⭐' : '1'), findsOneWidget);
      await _tapVisible(tester, find.text('متابعة'));
      expect(_round(game, 2), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('$game retains the final answer without exceeding eight rounds', (tester) async {
      service.profile.value = service.profile.value.copyWith(noTimedInteractions: true);
      await tester.pumpWidget(MaterialApp(home: _game(game)));
      for (var round = 1; round <= 8; round++) {
        await _tapVisible(tester, _answer(tester, game));
        expect(_round(game, round), findsOneWidget);
        if (round < 8) await _tapVisible(tester, find.text('متابعة'));
      }
      await tester.pump(const Duration(seconds: 10));
      await _tapVisible(tester, _answer(tester, game));
      expect(_round(game, 8), findsOneWidget);
      expect(find.text(game == 'sign' ? 'النقاط: 8 ⭐' : '8'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('$game advances once automatically and pauses in background', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(MaterialApp(home: _game(game)));
      await _tapVisible(tester, _answer(tester, game));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      expect(_round(game, 1), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(_round(game, 2), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(_round(game, 2), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      testWidgets('$game keeps Continue reachable at $size with large Arabic text', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        service.profile.value = service.profile.value.copyWith(
          noTimedInteractions: true, extraLargeTouchTargets: true);
        await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.8)),
          child: child!), home: _game(game)));
        expect(tester.takeException(), isNull);
        await _tapVisible(tester, _answer(tester, game));
        expect(tester.takeException(), isNull);
        await _tapVisible(tester, find.text('متابعة'));
        expect(_round(game, 2), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final game in ['symbols', 'words']) {
    for (final mode in ['disabled', 'calm', 'slow']) {
      testWidgets('$game automatic speech respects $mode preference', (tester) async {
        final calls = <MethodCall>[];
        const channel = MethodChannel('flutter_tts');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 1;
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
        service.profile.value = AccessibilityProfile(type: DisabilityType.none,
          autoReadOnTap: mode != 'disabled', sensoryCalmMode: mode == 'calm',
          slowSpeech: mode == 'slow', noTimedInteractions: true);
        await tester.pumpWidget(MaterialApp(home: _game(game)));
        await tester.pump();
        await _tapVisible(tester, _answer(tester, game));
        await tester.pump();
        if (mode == 'slow') {
          expect(calls.where((call) => call.method == 'speak'), isNotEmpty);
          expect(calls.where((call) => call.method == 'setSpeechRate').last.arguments, 0.30);
        } else {
          expect(calls.where((call) => call.method == 'speak'), isEmpty);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
