import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:edubridge_app/games/choice_learning_game.dart';
import 'package:edubridge_app/screens/educational_games_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/encouragement_service.dart';
import 'package:edubridge_app/widgets/accessibility/child_color_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RouteObserver extends NavigatorObserver {
  final opened = Completer<void>();
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && !opened.isCompleted) opened.complete();
  }
}

void main() {
  final service = AccessibilityService.instance;
  setUp(() {
    service.resetSession();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(service.resetSession);

  testWidgets('filter changes rendered colours, preserves neutrals and restores originals',
      (tester) async {
    final capture = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Center(child: RepaintBoundary(
      key: capture,
      child: ChildColorFilter(child: Row(mainAxisSize: MainAxisSize.min,
        children: [for (final color in [Colors.red, Colors.black, Colors.white])
          SizedBox(width: 40, height: 40, child: ColoredBox(color: color)),
        ],
      )),
    ))));

    Future<ByteData> pixels() async {
      final boundary = capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final result = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        } finally {
          image.dispose();
        }
      });
      return result!;
    }
    List<int> pixel(ByteData data, int x) =>
        List.generate(4, (channel) => data.getUint8((20 * 120 + x) * 4 + channel));

    final original = await pixels();
    service.profile.value = service.profile.value.copyWith(colorFiltersEnabled: true);
    await tester.pump();
    final filtered = await pixels();
    expect(pixel(filtered, 20)[0], lessThan(pixel(original, 20)[0]));
    expect(pixel(filtered, 20)[1], greaterThan(pixel(original, 20)[1]));
    expect(pixel(filtered, 60), pixel(original, 60));
    expect(pixel(filtered, 100), pixel(original, 100));
    service.profile.value = service.profile.value.copyWith(colorFiltersEnabled: false);
    await tester.pump();
    expect((await pixels()).buffer.asUint8List(), original.buffer.asUint8List());
  });

  testWidgets('toggling preserves focus, typed input and tap actions', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChildColorFilter(
      child: Column(children: [
        const TextField(),
        TextButton(onPressed: () => taps++, child: const Text('افتح')),
      ]),
    ))));
    await tester.enterText(find.byType(TextField), 'إجابة الطفل');
    service.profile.value = service.profile.value.copyWith(colorFiltersEnabled: true,
        highContrast: true, simpleIconsGrid: true, sensoryCalmMode: true);
    await tester.pump();
    expect(find.text('إجابة الطفل'), findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.tap(find.text('افتح'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('protected specialist view keeps the original filter', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const ChildColorFilter(
      enabled: false, child: Text('عرض المختص'),
    )));
    final current = tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter;
    service.profile.value = service.profile.value.copyWith(colorFiltersEnabled: true);
    await tester.pump();
    expect(tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter, current);
  });

  testWidgets('a colour game launched from filtered catalog has no filter ancestor',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null));
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
        colorFiltersEnabled: true, simpleIconsGrid: true);
    final observer = _RouteObserver();
    final encouragement = EncouragementService(profile: () => service.profile.value,
        speak: (_) async {}, speakSlow: (_) async {});
    await tester.pumpWidget(MaterialApp(navigatorObservers: [observer],
      home: EducationalGamesScreen(childName: 'طفل', age: 5,
          encouragement: encouragement),
    ));
    await tester.ensureVisible(find.byKey(const ValueKey('simple_game_colors_simple')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الألوان'));
    await tester.runAsync(() => observer.opened.future.timeout(const Duration(seconds: 5)));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceLearningGame), findsOneWidget);
    expect(find.ancestor(of: find.byType(ChoiceLearningGame),
        matching: find.byType(ColorFiltered)), findsNothing);
    Navigator.of(tester.element(find.byType(ChoiceLearningGame))).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
