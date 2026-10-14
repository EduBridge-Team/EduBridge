import 'dart:async';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/game_round_continuation.dart';
import 'package:edubridge_app/games/logic_puzzle_game.dart';
import 'package:edubridge_app/games/advanced_reading_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AccessibilityService.instance;
  tearDown(service.resetSession);
  Widget screen(Future<void> Function() next) => MaterialApp(home: Scaffold(body:
    GameRoundContinuation(answered: true, delay: const Duration(seconds: 1), onContinue: next)));

  testWidgets('untimed answers stay until explicit continuation and cannot submit twice', (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none, noTimedInteractions: true);
    var calls = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(screen(() { calls++; return pending.future; }));
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 0);
    await tester.tap(find.text('متابعة'));
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disabling timed interaction cancels a scheduled advance', (tester) async {
    var calls = 0;
    await tester.pumpWidget(screen(() async { calls++; }));
    await tester.pump(const Duration(milliseconds: 400));
    service.profile.value = service.profile.value.copyWith(noTimedInteractions: true);
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 0);
    await tester.tap(find.text('متابعة'));
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('automatic continuation pauses in background and cancels on disposal', (tester) async {
    var calls = 0;
    await tester.pumpWidget(screen(() async { calls++; }));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 1);
  });

  testWidgets('a failed continuation can be retried manually without automatic retries', (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none, noTimedInteractions: true);
    var calls = 0;
    await tester.pumpWidget(screen(() async {
      if (++calls == 1) throw StateError('Retry');
    }));
    await tester.tap(find.text('متابعة'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1);
    await tester.tap(find.text('متابعة'));
    await tester.pump();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final reading in [false, true]) {
    testWidgets('quiz retains its answered round until Continue, reading=$reading', (tester) async {
      service.profile.value = const AccessibilityProfile(type: DisabilityType.none, noTimedInteractions: true);
      await tester.pumpWidget(MaterialApp(home: reading
        ? const AdvancedReadingGame(childName: 'محمود')
        : const LogicPuzzleGame(childName: 'محمود')));
      final answer = reading ? find.byType(OutlinedButton).first : find.byType(ElevatedButton).first;
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pump();
      final text = tester.widget<Text>(find.byWidgetPredicate((widget) => widget is Text &&
        (widget.data == 'إجابة صحيحة' || widget.data == 'حاول أن تفكر في العلاقة بين المعلومات' ||
         widget.data == 'ممتاز، فهمت النص جيداً' || widget.data == 'ارجع للنص وابحث عن الفكرة الأساسية'))).data!;
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(text), findsOneWidget);
      await tester.ensureVisible(find.text('متابعة'));
      await tester.tap(find.text('متابعة'));
      await tester.pump();
      expect(find.text(text), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
