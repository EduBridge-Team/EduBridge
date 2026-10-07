import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubridge_app/games/game_content.dart';
import 'package:edubridge_app/games/learning_rounds.dart';
import 'package:edubridge_app/games/math_race_game.dart';
import 'package:flutter/material.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('replays use unseen content before recycling the oldest items', () async {
    final content = GameContent(random: Random(3));
    await content.prepare(ownerId: 1, childId: 10);
    final bank = List.generate(12, (i) => '$i');
    final first = content.take('words', bank, 6, (item) => item);
    final second = content.take('words', bank, 6, (item) => item);
    expect({...first, ...second}.length, 12);
    final third = content.take('words', bank, 6, (item) => item);
    expect(third.toSet(), first.toSet());
    expect(third.toSet().length, 6);
    await content.settled;
  });

  test('history survives restart and stays isolated per account and child', () async {
    final first = GameContent(random: Random(5));
    await first.prepare(ownerId: 1, childId: 10);
    final bank = ['a', 'b', 'c', 'd'];
    final used = first.take('words', bank, 3, (item) => item);
    await first.settled;
    final restarted = GameContent(random: Random(5));
    await restarted.prepare(ownerId: 1, childId: 10);
    expect(used, isNot(contains(restarted.pick<String>('words', bank, (item) => item))));
    final otherChild = GameContent(random: Random(5));
    await otherChild.prepare(ownerId: 1, childId: 20);
    expect(otherChild.take('words', bank, 3, (item) => item), used);
    await otherChild.settled;
    await restarted.prepare(ownerId: 2, childId: 10);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('game_content_v1_2_10_words'), isFalse);
    await restarted.settled;
  });

  test('small banks terminate and batch selection never duplicates items', () {
    final content = GameContent(random: Random(1));
    expect(content.take('one', ['x', 'x'], 4, (item) => item), ['x']);
    expect(() => content.pick<String>('empty', [], (item) => item), throwsArgumentError);
    expect(content.pick('one', ['x'], (item) => item), 'x');
  });

  test('choice difficulty rises after success and eases after help', () {
    final rounds = LearningRounds(itemCount: 6, totalRounds: 5,
      optionCount: 3, adaptiveOptions: true, random: Random(2));
    rounds.choose(rounds.target); rounds.next();
    expect(rounds.options.length, 3);
    rounds.choose(rounds.target); rounds.next();
    expect(rounds.options.length, 4);
    rounds.hint(); rounds.choose(rounds.target); rounds.next();
    expect(rounds.options.length, 3);
  });

  testWidgets('arithmetic choices stay in place when the timer rebuilds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MathRaceGame(childName: 'طفل', age: 7)));
    List<String> choices() => tester.widgetList<Text>(find.descendant(
      of: find.byType(ElevatedButton), matching: find.byType(Text)))
        .map((text) => text.data!).toList();
    final before = choices();
    expect(before.length, 4);
    expect(before.toSet().length, 4);
    await tester.pump(const Duration(seconds: 2));
    expect(choices(), before);
    await tester.pumpWidget(const SizedBox());
  });
}
