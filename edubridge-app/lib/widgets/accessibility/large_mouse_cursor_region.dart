part of 'large_mouse_cursor.dart';

class _CursorRegion extends SingleChildRenderObjectWidget {
  const _CursorRegion({
    required this.enabled,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
    required this.onShape,
    required super.child,
  });
  final bool enabled;
  final PointerEnterEventListener onEnter;
  final PointerHoverEventListener onHover;
  final PointerExitEventListener onExit;
  final ValueChanged<_CursorShape> onShape;

  @override
  _RenderCursorRegion createRenderObject(BuildContext context) =>
      _RenderCursorRegion(enabled: enabled, onEnter: onEnter, onHover: onHover,
          onExit: onExit, onShape: onShape);

  @override
  void updateRenderObject(BuildContext context, _RenderCursorRegion renderObject) {
    renderObject
      ..onEnter = onEnter
      ..onHover = onHover
      ..onExit = onExit
      ..onShape = onShape
      ..enabled = enabled;
  }
}

/// Put this cursor annotation ahead of descendant cursor annotations, without
/// removing their hit targets or hover callbacks. A normal outer MouseRegion
/// loses to button/text-field cursors and would leave two visible cursors.
class _RenderCursorRegion extends RenderMouseRegion {
  _RenderCursorRegion({
    required bool enabled,
    required super.onEnter,
    required super.onHover,
    required super.onExit,
    required this.onShape,
  }) : _enabled = enabled;

  bool _enabled;
  ValueChanged<_CursorShape> onShape;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    cursor = MouseCursor.defer;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_enabled) return super.hitTest(result, position: position);
    if (!size.contains(position)) return false;
    final ownEntry = BoxHitTestEntry(this, position);
    result.add(ownEntry);
    final hit = hitTestChildren(result, position: position) || hitTestSelf(position);
    var afterSelf = false;
    MouseCursor resolved = SystemMouseCursors.basic;
    for (final entry in result.path) {
      if (identical(entry, ownEntry)) {
        afterSelf = true;
        continue;
      }
      final Object target = entry.target;
      if (afterSelf && target is MouseTrackerAnnotation &&
          target.validForMouseTracker && target.cursor != MouseCursor.defer) {
        resolved = target.cursor;
        break;
      }
    }
    final shape = resolved == SystemMouseCursors.text ? _CursorShape.text
        : resolved == SystemMouseCursors.basic || resolved == SystemMouseCursors.click
            ? _CursorShape.arrow : _CursorShape.native;
    // Preserve native resize, forbidden, grabbing, wait and platform-view cursors.
    cursor = shape == _CursorShape.native ? resolved : SystemMouseCursors.none;
    onShape(shape);
    return hit;
  }
}
