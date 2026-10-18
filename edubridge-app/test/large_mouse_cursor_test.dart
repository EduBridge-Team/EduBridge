import 'dart:ui' as ui;
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/child_mouse_cursor.dart';
import 'package:edubridge_app/widgets/accessibility/large_mouse_cursor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ByteData> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final data = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } finally {
      image.dispose();
    }
  });
  return data!;
}

List<int> _pixel(ByteData data, int width, Offset point) => List.generate(4,
    (channel) => data.getUint8((point.dy.toInt() * width + point.dx.toInt()) * 4 + channel));

Widget _host(Widget child, {bool enabled = true, GlobalKey? capture}) => MaterialApp(
  home: RepaintBoundary(key: capture, child: LargeMouseCursor(enabled: enabled,
    child: Scaffold(backgroundColor: Colors.red, body: child))),
);

void main() {
  final service = AccessibilityService.instance;
  tearDown(service.resetSession);

  testWidgets('one painted cursor replaces button cursor and clicks reach exact target',
      (tester) async {
    final capture = GlobalKey();
    var taps = 0;
    var enters = 0;
    var exits = 0;
    Offset? down;
    await tester.pumpWidget(_host(Center(child: MouseRegion(
      onEnter: (_) => enters++, onExit: (_) => exits++,
      child: Listener(onPointerDown: (event) => down = event.position,
        child: TextButton(onPressed: () => taps++, child: const Text('افتح'))),
    )), capture: capture));
    final mouse = TestGesture(dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse, device: 1);
    await mouse.addPointer(location: const Offset(10, 10));
    final point = tester.getCenter(find.text('افتح'));
    await mouse.moveTo(point);
    await tester.pump();
    expect(tester.binding.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.none);
    expect(enters, 1);
    final pixels = await _pixels(tester, capture);
    // Arrow body is visible below the hotspot, outside the button's text.
    final sample = _pixel(pixels, 800, point + const Offset(4, 27));
    expect(sample.take(3), isNot([244, 67, 54]));
    await mouse.down(point);
    await mouse.up();
    await tester.pump();
    expect(taps, 1);
    expect(down, point);
    await mouse.moveTo(const Offset(10, 10));
    await tester.pump();
    expect(exits, 1);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('text cursor is enlarged and disabling restores native text cursor and input',
      (tester) async {
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(MaterialApp(home: ValueListenableBuilder<bool>(
      valueListenable: enabled,
      builder: (context, value, _) => LargeMouseCursor(enabled: value,
        child: const Scaffold(body: Center(child: TextField()))),
    )));
    final mouse = TestGesture(dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse, device: 1);
    final point = tester.getCenter(find.byType(TextField));
    await mouse.addPointer(location: point);
    await mouse.moveTo(point);
    await tester.pump();
    expect(tester.binding.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.none);
    await tester.enterText(find.byType(TextField), 'إجابة الطفل');
    enabled.value = false;
    await tester.pumpAndSettle();
    expect(tester.binding.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    expect(find.text('إجابة الطفل'), findsOneWidget);
    enabled.value = true;
    await tester.pumpAndSettle();
    expect(tester.binding.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.none);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final cursor in [SystemMouseCursors.resizeLeftRight,
      SystemMouseCursors.forbidden, SystemMouseCursors.grabbing]) {
    testWidgets('special native cursor $cursor is preserved', (tester) async {
      await tester.pumpWidget(_host(MouseRegion(cursor: cursor,
        child: const SizedBox.expand())));
      final mouse = TestGesture(dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse, device: 1);
      await mouse.addPointer(location: const Offset(80, 80));
      await mouse.moveTo(const Offset(90, 90));
      await tester.pump();
      expect(tester.binding.mouseTracker.debugDeviceActiveCursor(1), cursor);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('touch and application pause leave no painted cursor', (tester) async {
    final capture = GlobalKey();
    await tester.pumpWidget(_host(const SizedBox.expand(), capture: capture));
    final original = await _pixels(tester, capture);
    await tester.tapAt(const Offset(100, 100));
    await tester.pump();
    expect((await _pixels(tester, capture)).buffer.asUint8List(), original.buffer.asUint8List());
    final mouse = TestGesture(dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse, device: 1);
    await mouse.addPointer(location: const Offset(100, 100));
    await mouse.moveTo(const Offset(120, 120));
    await tester.pump();
    final drawn = await _pixels(tester, capture);
    expect(_pixel(drawn, 800, const Offset(124, 140)), isNot(_pixel(original, 800, const Offset(124, 140))));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // Paused apps intentionally do not paint frames. Verify the cleared cursor
    // on the first resumed frame instead of capturing the cached paused layer.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect((await _pixels(tester, capture)).buffer.asUint8List(), original.buffer.asUint8List());
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mouse drag and drop reaches the existing target', (tester) async {
    int? accepted;
    await tester.pumpWidget(_host(Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Draggable<int>(data: 7,
          feedback: const SizedBox(width: 40, height: 40, child: ColoredBox(color: Colors.blue)),
          child: const SizedBox(key: ValueKey('source'), width: 80, height: 80,
              child: ColoredBox(color: Colors.blue))),
        DragTarget<int>(onAcceptWithDetails: (details) => accepted = details.data,
          builder: (context, candidates, rejected) => const SizedBox(
            key: ValueKey('target'), width: 120, height: 120,
            child: ColoredBox(color: Colors.green))),
      ],
    )));
    final mouse = TestGesture(dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse, device: 1);
    final source = tester.getCenter(find.byKey(const ValueKey('source')));
    final target = tester.getCenter(find.byKey(const ValueKey('target')));
    await mouse.addPointer(location: source);
    await mouse.down(source);
    await mouse.moveTo(source + const Offset(30, 0));
    await tester.pump();
    await mouse.moveTo(target);
    await tester.pump();
    await mouse.up();
    await tester.pumpAndSettle();
    expect(accepted, 7);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('hover repaint does not rebuild child content and scrolling still works',
      (tester) async {
    var builds = 0;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(_host(Builder(builder: (context) {
      builds++;
      return ListView(controller: scroll, children: [for (var i = 0; i < 30; i++)
        SizedBox(height: 70, child: Text('نشاط $i'))]);
    })));
    final before = builds;
    final mouse = TestGesture(dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse, device: 1);
    await mouse.addPointer(location: const Offset(50, 50));
    await mouse.moveTo(const Offset(70, 80));
    await tester.pump();
    await mouse.moveTo(const Offset(90, 100));
    await tester.pump();
    expect(builds, before);
    await tester.sendEventToBinding(const PointerScrollEvent(
      device: 1, position: Offset(90, 100), scrollDelta: Offset(0, 200)));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('cursor follows active child and clears when account scope is restored',
      (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
        largeMouseCursor: true);
    await tester.pumpWidget(const MaterialApp(home: ChildMouseCursor(
      child: Scaffold(body: Text('المحتوى')))));
    expect(tester.widget<LargeMouseCursor>(find.byType(LargeMouseCursor)).enabled, isFalse);
    service.activeChildId.value = 9;
    await tester.pump();
    expect(tester.widget<LargeMouseCursor>(find.byType(LargeMouseCursor)).enabled, isTrue);
    service.profile.value = service.profile.value.copyWith(largeMouseCursor: false);
    await tester.pump();
    expect(tester.widget<LargeMouseCursor>(find.byType(LargeMouseCursor)).enabled, isFalse);
    service.profile.value = service.profile.value.copyWith(largeMouseCursor: true);
    service.activeChildId.value = null;
    await tester.pump();
    expect(tester.widget<LargeMouseCursor>(find.byType(LargeMouseCursor)).enabled, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
