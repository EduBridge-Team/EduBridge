import 'dart:async';
import 'dart:convert';
import 'package:edubridge_app/features/games/application/game_launch_coordinator.dart';
import 'package:edubridge_app/features/games/application/game_screen_factory.dart';
import 'package:edubridge_app/features/games/domain/game_player.dart';
import 'package:edubridge_app/games/math_race_game.dart';
import 'package:edubridge_app/games/story_sequencer_game.dart';
import 'package:edubridge_app/games/visual_words_game.dart';
import 'package:edubridge_app/services/game_progress_service.dart';
import 'package:edubridge_app/utils/game_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const child = GamePlayer(childId: 23, name: 'محمود', age: 5);

  test('factory supports every catalog entry without defaulting child identity', () {
    for (final game in kGameCatalog) {
      expect(GameScreenFactory.build(game.id, child), isNotNull, reason: game.id);
    }
    final visual = GameScreenFactory.build('visual_words', child)! as VisualWordsGame;
    expect(visual.childName, 'محمود');
    expect(visual.age, 5);
    final story = GameScreenFactory.build('story', child)! as StorySequencerGame;
    expect(story.childName, 'محمود');
    expect(story.age, 5);
    final math = GameScreenFactory.build('math', child)! as MathRaceGame;
    expect(math.age, 5);
    expect(GameScreenFactory.info('math')!.id, 'numbers_math');
    expect(GameScreenFactory.info('not-a-game'), isNull);
    expect(GameScreenFactory.build('not-a-game', child), isNull);
  });

  test('child data accepts API strings but never substitutes age or name', () {
    expect(GamePlayer.fromChild({'id': '23', 'age': '5', 'name': ' محمود '})!.name, 'محمود');
    for (final data in [
      {'id': 23, 'name': 'محمود'}, {'id': 23, 'age': 5, 'name': ''},
      {'id': 0, 'age': 5, 'name': 'محمود'},
    ]) {
      expect(GamePlayer.fromChild(data), isNull);
    }
  });

  test('duplicate entry points cannot replace a preparing or active game', () async {
    final coordinator = GameLaunchCoordinator();
    final preparing = Completer<void>();
    final route = Completer<void>();
    final events = <String>[];
    Future<bool> launch() => coordinator.run(prepare: () => preparing.future,
      canOpen: () async => true, begin: () => events.add('begin'),
      open: () { events.add('open'); return route.future; }, end: () => events.add('end'));
    final first = launch();
    expect(await launch(), isFalse);
    preparing.complete();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['begin', 'open']);
    expect(await launch(), isFalse);
    route.complete();
    expect(await first, isTrue);
    expect(events, ['begin', 'open', 'end']);
    expect(coordinator.busy, isFalse);
  });

  test('leaving or switching account during preparation never begins a session', () async {
    final coordinator = GameLaunchCoordinator();
    final events = <String>[];
    final opened = await coordinator.run(prepare: () async {}, canOpen: () async => false,
      begin: () => events.add('begin'), open: () async { events.add('open'); },
      end: () => events.add('end'));
    expect(opened, isFalse);
    expect(events, isEmpty);
    expect(coordinator.busy, isFalse);
  });

  for (final failsPreparing in [true, false]) {
    test('failed launch releases the guard and ends only a started session, preparing=$failsPreparing', () async {
      final coordinator = GameLaunchCoordinator();
      var ends = 0;
      await expectLater(() => coordinator.run(
        prepare: () async { if (failsPreparing) throw StateError('prepare'); },
        canOpen: () async => true, begin: () {},
        open: () async { throw StateError('route'); }, end: () { ends++; }),
        throwsStateError);
      expect(ends, failsPreparing ? 0 : 1);
      expect(coordinator.busy, isFalse);
      expect(await coordinator.run(prepare: () async {}, canOpen: () async => true,
        begin: () {}, open: () async {}, end: () {}), isTrue);
    });
  }

  test('shared launch records the selected child and canonical game and clears on return', () async {
    SharedPreferences.setMockInitialValues({'userId': 1});
    final progress = GameProgressService(post: (_, __) async => http.Response('{}', 503));
    await GameLaunchCoordinator().run(prepare: progress.flushPending, canOpen: () async => true,
      begin: () => progress.begin(childId: child.childId, gameKey: GameScreenFactory.canonicalId('math')),
      open: () => progress.record(90), end: progress.end);
    await progress.record(20);
    final prefs = await SharedPreferences.getInstance();
    final queue = jsonDecode(prefs.getString('pending_game_attempts_v2_1')!) as List;
    expect(queue.length, 1);
    expect(queue.single['child_id'], 23);
    expect(queue.single['game_key'], 'numbers_math');
    expect(queue.single['score'], 90);
  });
}
