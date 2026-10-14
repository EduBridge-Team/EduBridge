import 'package:edubridge_app/games/story_sequencer_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AccessibilityService.instance;
  tearDown(service.resetSession);

  testWidgets('wrong order stays visible until the child retries', (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      noTimedInteractions: true, sensoryCalmMode: true);
    await tester.pumpWidget(const MaterialApp(home: StorySequencerGame(childName: 'نور')));
    // OrderedRound guarantees the initial choice order differs from the solution.
    final cards = find.byWidgetPredicate((w) => w is GestureDetector && w.onTap != null &&
      w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('story_choice_'));
    final initialCards = cards.evaluate().map((e) => e.widget.key!).toList();
    expect(initialCards.length, 4);
    for (final card in initialCards) {
      final target = find.byKey(card);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('خلينا نحاول مرة ثانية، فكّر بترتيب الأحداث'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('حاول مرة أخرى'), findsOneWidget);
    await tester.ensureVisible(find.text('حاول مرة أخرى'));
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pump();
    expect(find.text('خلينا نحاول مرة ثانية، فكّر بترتيب الأحداث'), findsNothing);
    expect(cards, findsNWidgets(4));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
