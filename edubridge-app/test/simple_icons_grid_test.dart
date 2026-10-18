import 'package:edubridge_app/screens/child_lessons/child_lessons_screen.dart';
import 'package:edubridge_app/screens/educational_games_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/encouragement_service.dart';
import 'package:edubridge_app/utils/game_catalog.dart';
import 'package:edubridge_app/widgets/accessibility/simple_icons_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AccessibilityService.instance;
  tearDown(service.resetSession);

  test('grid setting survives the existing profile serialization', () {
    const profile = AccessibilityProfile(type: DisabilityType.none,
        simpleIconsGrid: true);
    expect(AccessibilityProfile.fromJson(profile.toJson()).simpleIconsGrid, isTrue);
    expect(profile.copyWith(simpleIconsGrid: false).simpleIconsGrid, isFalse);
  });

  testWidgets('catalog responds to the setting without removing eligible games',
      (tester) async {
    final encouragement = EncouragementService(
      profile: () => service.profile.value,
      speak: (_) async {}, speakSlow: (_) async {},
    );
    await tester.pumpWidget(MaterialApp(home: EducationalGamesScreen(
      childName: 'طفل', encouragement: encouragement,
    )));
    await tester.pump();
    expect(find.byType(SimpleIconsGrid), findsNothing);
    final eligible = gamesFor(DisabilityType.none, ageGroupOf(8));
    service.profile.value = service.profile.value.copyWith(simpleIconsGrid: true);
    await tester.pump();
    expect(find.byType(SimpleIconsGrid), findsOneWidget);
    for (final game in eligible) {
      expect(find.byKey(ValueKey('simple_game_${game.id}')), findsOneWidget);
    }
    final last = find.byKey(ValueKey('simple_game_${eligible.last.id}'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(last.hitTestable(), findsOneWidget);
    service.profile.value = service.profile.value.copyWith(simpleIconsGrid: false);
    await tester.pump();
    expect(find.byType(SimpleIconsGrid), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final canMarkDone in [true, false]) {
    testWidgets('compact lesson preserves open/read and completion permission=$canMarkDone',
        (tester) async {
      service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
          simpleIconsGrid: true);
      var opened = 0;
      var read = 0;
      var completed = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
        builder: (context) => SingleChildScrollView(child: SimpleIconsGrid(
          children: [buildLessonCard(
            context: context,
            lesson: const {'id': 71, 'title': 'درس الطفل', 'content': 'محتوى كامل'},
            doneLessonIds: {}, speakingLessonId: null, savingLessonId: null,
            canMarkDone: canMarkDone,
            onOpenLesson: (_) => opened++,
            onToggleSpeak: (_) async { read++; },
            onMarkDone: (_) async { completed++; },
          )],
        )),
      ))));
      await tester.tap(find.text('درس الطفل'));
      await tester.pump();
      expect(opened, 1);
      await tester.tap(find.text('استمع'));
      await tester.pump();
      expect(read, 1);
      expect(opened, 1);
      if (canMarkDone) {
        await tester.tap(find.text('تمّ'));
        await tester.pump();
        expect(completed, 1);
        expect(opened, 1);
      } else {
        expect(find.text('تمّ'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final width in [360.0, 400.0]) {
  for (final scale in [1.0, 2.0]) {
    testWidgets('grid wraps large text and all tiles remain reachable at width $width and scale $scale',
        (tester) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
          simpleIconsGrid: true, extraLargeTouchTargets: true,
          iconOnlyMode: true, screenReaderOptimized: true);
      var selected = -1;
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: MediaQueryData(size: Size(width, 640),
            textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16),
          child: SimpleIconsGrid(children: [for (var i = 0; i < 8; i++)
            SimpleIconTile(key: ValueKey('tile_$i'),
              title: 'نشاط بعنوان واضح للطفل رقم $i', icon: Icons.category,
              onTap: () => selected = i),
          ]),
        )),
      )));
      final first = tester.getRect(find.byKey(const ValueKey('tile_0')));
      final second = tester.getRect(find.byKey(const ValueKey('tile_1')));
      expect(first.height, greaterThanOrEqualTo(88));
      if (scale == 1 && width >= 400) {
        expect(first.top, second.top);
      } else {
        expect(second.top, greaterThan(first.bottom));
      }
      final last = find.byKey(const ValueKey('tile_7'));
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('نشاط بعنوان واضح للطفل رقم 7'));
      await tester.pump();
      expect(selected, 7);
      expect(tester.takeException(), isNull);
    });
  }
  }
}
