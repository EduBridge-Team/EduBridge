import 'dart:convert';
import 'package:edubridge_app/screens/educational_games_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/encouragement_service.dart';
import 'package:edubridge_app/utils/game_catalog.dart';
import 'package:edubridge_app/widgets/accessibility/child_mouse_cursor.dart';
import 'package:edubridge_app/widgets/accessibility/large_mouse_cursor.dart';
import 'package:edubridge_app/widgets/accessibility/simple_icons_grid.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _combined = AccessibilityProfile(type: DisabilityType.none,
  simpleIconsGrid: true, colorFiltersEnabled: true, largeMouseCursor: true,
  extraLargeTouchTargets: true, highContrast: true, reducedAnimations: true,
  sensoryCalmMode: true, noTimers: true,
);
const _plain = AccessibilityProfile(type: DisabilityType.none);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AccessibilityService.instance;
  setUp(() async {
    service.resetSession();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 1, 'role': 'specialist'});
    await service.load();
  });
  tearDown(service.resetSession);

  test('specialist save survives reload and offline child switching without changing account', () async {
    var saves = 0;
    await http.runWithClient(() async {
      await service.updateForChild(9, _combined);
      expect(saves, 1);
      expect(service.applicationProfile.value.toJson(), _plain.toJson());
      service.resetSession();
      await service.load();
      // Offline reads must recover the successful save, not infer a diagnosis.
      await service.setActiveChild(9);
      expect(service.profile.value.toJson(), _combined.toJson());
      await service.setActiveChild(10);
      expect(service.profile.value.toJson(), _plain.toJson());
      await service.setActiveChild(9);
      expect(service.profile.value.toJson(), _combined.toJson());
      await service.setActiveChild(null);
      expect(service.profile.value.toJson(), _plain.toJson());
      expect(service.applicationProfile.value.toJson(), _plain.toJson());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', 2);
      await service.load();
      expect(service.allChildProfiles, isEmpty);
      expect(service.profile.value.toJson(), _plain.toJson());
    }, () => MockClient((request) async {
      if (request.method == 'PUT') {
        saves++;
        expect(request.url.path, endsWith('/children/9/accessibility-profile'));
        expect(jsonDecode(request.body)['profile'], _combined.toJson());
        return http.Response('{}', 200);
      }
      throw http.ClientException('offline');
    }));
  });

  for (final status in [403, 500]) {
    test('rejected specialist save ($status) preserves previous child and stored settings', () async {
      await http.runWithClient(() async {
        await service.setActiveChild(9);
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('acc_user_1_child_9');
        await expectLater(service.updateForChild(9, _combined), throwsStateError);
        expect(service.profile.value.toJson(), _plain.toJson());
        expect(service.profileForChild(9)!.toJson(), _plain.toJson());
        expect(prefs.getString('acc_user_1_child_9'), stored);
        expect(service.applicationProfile.value.toJson(), _plain.toJson());
      }, () => MockClient((request) async => request.method == 'PUT'
          ? http.Response('{}', status)
          : http.Response(jsonEncode({'profile': _plain.toJson()}), 200)));
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('combined catalog keeps every game reachable and restores ordinary child at scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      service.activeChildId.value = 9;
      service.profile.value = _combined;
      final encouragement = EncouragementService(profile: () => service.profile.value,
          speak: (_) async {}, speakSlow: (_) async {});
      Offset? pointerDown;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: ChildMouseCursor(child: child!),
        ),
        home: Listener(onPointerDown: (event) => pointerDown = event.position,
          child: EducationalGamesScreen(childName: 'طفل', encouragement: encouragement)),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleIconsGrid), findsOneWidget);
      expect(tester.widget<LargeMouseCursor>(find.byType(LargeMouseCursor)).enabled, isTrue);
      final activeFilter = tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter;
      final games = gamesFor(DisabilityType.none, ageGroupOf(8));
      for (final game in games) {
        expect(find.byKey(ValueKey('simple_game_${game.id}')), findsOneWidget);
      }
      final last = find.byKey(ValueKey('simple_game_${games.last.id}'));
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
      // A real mouse must keep an accurate hotspot through filter/grid/layout.
      final mouse = TestGesture(dispatcher: tester.sendEventToBinding,
          kind: PointerDeviceKind.mouse, device: 1);
      await mouse.addPointer(location: tester.getCenter(last));
      await mouse.moveTo(tester.getCenter(last));
      await tester.pump();
      expect(tester.binding.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.none);
      final target = tester.getCenter(last);
      await mouse.down(target);
      expect(pointerDown, target);
      await mouse.cancel();
      await mouse.removePointer();
      // Same mounted catalog receives the next child's settings.
      service.activeChildId.value = 10;
      service.profile.value = _plain;
      await tester.pumpAndSettle();
      expect(find.byType(SimpleIconsGrid), findsNothing);
      expect(tester.widget<LargeMouseCursor>(find.byType(LargeMouseCursor)).enabled, isFalse);
      expect(tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter, isNot(activeFilter));
      expect(service.applicationProfile.value.toJson(), _plain.toJson());
      expect(service.profile.value.eyeTrackingOptimized, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
