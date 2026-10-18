import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

part 'large_mouse_cursor_region.dart';

enum _CursorShape { arrow, text, native }

class _CursorVisual {
  const _CursorVisual(this.position, this.shape);
  final Offset? position;
  final _CursorShape shape;
}

/// One large Flutter cursor, with the native cursor hidden only for supported
/// shapes. It is paint-only: clicks, drags, selection and scrolling go through.
class LargeMouseCursor extends StatefulWidget {
  const LargeMouseCursor({super.key, required this.enabled, required this.child});
  final bool enabled;
  final Widget child;

  @override
  State<LargeMouseCursor> createState() => _LargeMouseCursorState();
}

class _LargeMouseCursorState extends State<LargeMouseCursor>
    with WidgetsBindingObserver {
  final _visual = ValueNotifier(const _CursorVisual(null, _CursorShape.arrow));
  Offset? _mousePosition;
  _CursorShape _shape = _CursorShape.arrow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant LargeMouseCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) _refreshVisual();
  }

  void _refreshVisual() {
    final position = widget.enabled ? _mousePosition : null;
    if (_visual.value.position == position && _visual.value.shape == _shape) return;
    _visual.value = _CursorVisual(position, _shape);
  }

  void _resolveShape(_CursorShape shape) {
    _shape = shape;
    _refreshVisual();
  }

  void _pointer(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) {
      _clearPosition();
      return;
    }
    _mousePosition = event.localPosition;
    _refreshVisual();
  }

  void _clearPosition() {
    _mousePosition = null;
    _refreshVisual();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _clearPosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _CursorRegion(
    enabled: widget.enabled,
    onEnter: _pointer,
    onHover: _pointer,
    onExit: (_) => _clearPosition(),
    onShape: _resolveShape,
    child: Listener(
      onPointerDown: _pointer,
      onPointerMove: _pointer,
      child: Stack(children: [
        widget.child,
        Positioned.fill(child: IgnorePointer(child: ExcludeSemantics(
          child: RepaintBoundary(child: CustomPaint(
            key: const ValueKey('large_mouse_cursor_paint'),
            painter: _LargeCursorPainter(_visual),
          )),
        ))),
      ]),
    ),
  );
}

class _LargeCursorPainter extends CustomPainter {
  _LargeCursorPainter(this.visual) : super(repaint: visual);
  final ValueNotifier<_CursorVisual> visual;

  @override
  void paint(Canvas canvas, Size size) {
    final position = visual.value.position;
    if (position == null || visual.value.shape == _CursorShape.native) return;
    canvas.save();
    canvas.translate(position.dx, position.dy);
    final path = Path();
    if (visual.value.shape == _CursorShape.text) {
      path.moveTo(0, -18);
      path.lineTo(0, 18);
      path.moveTo(-7, -18);
      path.lineTo(7, -18);
      path.moveTo(-7, 18);
      path.lineTo(7, 18);
      canvas.drawPath(path, Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 6);
      canvas.drawPath(path, Paint()..color = Colors.black
        ..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      // Flip only the body near edges; the tip stays at the real hit position.
      canvas.scale(position.dx + 28 > size.width ? -1 : 1,
          position.dy + 42 > size.height ? -1 : 1);
      path.moveTo(0, 0);
      path.lineTo(0, 32);
      path.lineTo(8, 25);
      path.lineTo(15, 40);
      path.lineTo(21, 37);
      path.lineTo(14, 23);
      path.lineTo(26, 23);
      path.close();
      canvas.drawPath(path, Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 5);
      canvas.drawPath(path, Paint()..color = Colors.white);
      canvas.drawPath(path, Paint()..color = Colors.black
        ..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LargeCursorPainter oldDelegate) =>
      oldDelegate.visual != visual;
}
