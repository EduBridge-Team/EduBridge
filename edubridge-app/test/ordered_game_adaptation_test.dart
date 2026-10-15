import 'package:edubridge_app/games/sequence_game.dart';
import 'package:edubridge_app/games/word_builder_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AccessibilityService.instance;
  tearDown(service.resetSession);

  Finder cards(String prefix) => find.byWidgetPredicate((w) => w is GestureDetector &&
    w.onTap != null && w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith(prefix));

  for (final words in [false, true]) {
    testWidgets('incorrect ordered game retains answer until retry, words=$words', (tester) async {
      service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
        noTimedInteractions: true, sensoryCalmMode: true);
      await tester.pumpWidget(MaterialApp(home: words
        ? const WordBuilderGame(childName: 'نور', age: 7)
        : const SequenceGame(childName: 'نور')));
      final prefix = words ? 'word_choice_' : 'sequence_choice_';
      final keys = cards(prefix).evaluate().map((e) => e.widget.key!).toList();
      // Initial choices deliberately differ from the solution.
      for (final key in keys) {
        await tester.ensureVisible(find.byKey(key));
        await tester.tap(find.byKey(key));
        await tester.pump();
      }
      final message = words ? 'خلينا نحاول مرة ثانية، رتّب حروف الكلمة'
        : 'خلينا نحاول مرة ثانية، فكّر بترتيب الأحداث';
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(message), findsOneWidget);
      expect(cards(prefix), findsNothing);
      await tester.ensureVisible(find.text('حاول مرة أخرى'));
      await tester.tap(find.text('حاول مرة أخرى'));
      await tester.pump();
      expect(find.text(message), findsNothing);
      expect(cards(prefix), findsNWidgets(keys.length));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('word builder supports repeated letters and untimed continuation', (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      noTimedInteractions: true, extraLargeTouchTargets: true);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: WordBuilderGame(childName: 'نور', age: 7)));
    final target = tester.widget<Text>(find.byWidgetPredicate((w) => w is Text &&
      (w.data?.startsWith('كوّن كلمة: ') ?? false))).data!.substring('كوّن كلمة: '.length);
    final options = cards('word_choice_').evaluate().map((e) {
      final text = find.descendant(of: find.byKey(e.widget.key!), matching: find.byType(Text));
      return (e.widget.key!, tester.widget<Text>(text).data!);
    }).toList();
    for (final letter in target.split('')) {
      final index = options.indexWhere((option) => option.$2 == letter);
      final key = options.removeAt(index).$1;
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('ممتاز! ترتيب صحيح'), findsOneWidget);
    expect(find.text('الجولة: 1/6'), findsOneWidget);
    expect(find.text('النقاط: 1 ⭐'), findsOneWidget);
    await tester.ensureVisible(find.text('متابعة'));
    await tester.tap(find.text('متابعة'));
    await tester.pump();
    expect(find.text('الجولة: 2/6'), findsOneWidget);
    expect(find.text('ممتاز! ترتيب صحيح'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
