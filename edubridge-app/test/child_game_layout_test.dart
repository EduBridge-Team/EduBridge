import 'package:edubridge_app/games/advanced_reading_game.dart';
import 'package:edubridge_app/games/logic_puzzle_game.dart';
import 'package:edubridge_app/games/quick_action_game.dart';
import 'package:edubridge_app/games/rhythm_game.dart';
import 'package:edubridge_app/games/sequence_game.dart';
import 'package:edubridge_app/games/story_sequencer_game.dart';
import 'package:edubridge_app/games/word_builder_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_button.dart';
import 'package:edubridge_app/widgets/accessibility/game_round_continuation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AccessibilityService.instance;
  setUp(() {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      extraLargeTouchTargets: true, sensoryCalmMode: true,
      noTimedInteractions: true, noTimers: true);
  });
  tearDown(service.resetSession);

  Widget app(Widget child) => MaterialApp(builder: (context, body) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.8)),
    child: Directionality(textDirection: TextDirection.rtl, child: body!)), home: child);

  final games = <String, (Widget, String)>{
    'story': (const StorySequencerGame(childName: 'نور'), 'البطاقات المتاحة:'),
    'sequence': (const SequenceGame(childName: 'نور'), 'اختر بالترتيب:'),
    'word': (const WordBuilderGame(childName: 'نور', age: 13), 'الحروف المتاحة:'),
    'quick action': (const QuickActionGame(childName: 'نور'), 'فعلتها!'),
    'rhythm': (const RhythmGame(childName: 'نور'), 'ابدأ'),
    'logic': (const LogicPuzzleGame(childName: 'نور'), 'النتيجة: 0'),
    'reading': (const AdvancedReadingGame(childName: 'نور'), 'استمع إلى النص'),
  };

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    for (final entry in games.entries) {
      testWidgets('${entry.key} remains reachable at $size with large Arabic text', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(app(entry.value.$1));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(entry.value.$2));
        await tester.pump();
        if (entry.key == 'rhythm') {
          await tester.tap(find.text('ابدأ'));
          await tester.pump();
          await tester.ensureVisible(find.text('متابعة'));
          await tester.pump();
          expect(find.text('الكلمة 1 من 8'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('continuation and adaptive controls honour large touch targets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var continued = 0;
    var pressed = 0;
    await tester.pumpWidget(app(Scaffold(body: SingleChildScrollView(child: Column(children: [
      GameRoundContinuation(answered: true, onContinue: () async { continued++; }),
      AdaptiveButton(label: 'أعد المحاولة عندما تكون جاهزاً', onPressed: () { pressed++; }),
    ])))));
    final next = find.byType(FilledButton);
    expect(tester.getSize(next).height, greaterThanOrEqualTo(88));
    final adaptive = find.byType(ElevatedButton);
    expect(tester.getSize(adaptive).height, greaterThanOrEqualTo(88));
    await tester.tap(next);
    await tester.pump();
    await tester.ensureVisible(adaptive);
    await tester.tap(adaptive);
    await tester.pump();
    expect(continued, 1);
    expect(pressed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
