import 'package:edubridge_app/games/matching_game.dart';
import 'package:edubridge_app/games/sign_language_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'userId': 1});
    AccessibilityService.instance.profile.value = const AccessibilityProfile(
      type: DisabilityType.none, sensoryCalmMode: true);
  });
  tearDown(() {
    AccessibilityService.instance.resetSession();
    GameProgressService.instance.end();
  });

  testWidgets('matching counts active time and cancels its timer on disposal', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const MaterialApp(home: MatchingGame(childName: 'نور')));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2 ث'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('2 ث'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('3 ث'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('restarting matching invalidates a pending pair resolution', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MatchingGame(childName: 'نور')));
    final cards = find.byWidgetPredicate((widget) =>
      widget is GestureDetector && widget.child is AnimatedContainer);
    await tester.tap(cards.at(0));
    await tester.tap(cards.at(1));
    await tester.tap(find.byTooltip('لعبة جديدة'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0/4'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving sign game before delayed completion cannot record for the next child', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const answers = {
      'أ': 'إصبع الإبهام مرفوع', 'ب': 'كف مفتوح مستقيم',
      'ت': 'إصبعان مفتوحان', 'ث': 'ثلاثة أصابع', 'ج': 'قبضة مغلقة',
      'ح': 'الإبهام والخنصر', 'خ': 'إصبعان متقاطعان', 'د': 'إصبع واحد مرفوع',
    };
    await tester.pumpWidget(const MaterialApp(home: SignLanguageGame(childName: 'نور')));
    for (var round = 0; round < 8; round++) {
      final target = tester.widget<Text>(find.byWidgetPredicate((widget) =>
        widget is Text && widget.style?.fontSize == 90));
      final answer = find.text(answers[target.data]!);
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      if (round < 7) await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    GameProgressService.instance.begin(childId: 99, gameKey: 'matching');
    await tester.pump(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pending_game_attempts_v2_1'), isNull);
    expect(tester.takeException(), isNull);
  });
}
