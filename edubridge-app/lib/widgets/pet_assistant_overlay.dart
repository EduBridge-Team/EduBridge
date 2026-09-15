import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/assistant_screen.dart';
import '../services/api_service.dart';
import '../services/overlay_visibility_service.dart';
import '../theme.dart';
import '../utils/navigation.dart';
import 'pet_avatar.dart';

class PetAssistantOverlay extends StatefulWidget {
  final Widget child;

  const PetAssistantOverlay({super.key, required this.child});

  @override
  State<PetAssistantOverlay> createState() => _PetAssistantOverlayState();
}

class _PetAssistantOverlayState extends State<PetAssistantOverlay> {
  static const double _launcherSize = 78;
  static const double _screenMargin = 14;
  static const String _xPreferenceKey = 'pet_assistant_x_fraction';
  static const String _yPreferenceKey = 'pet_assistant_y_fraction';

  final GlobalKey _overlayKey = GlobalKey();

  double _x = 0;
  double _y = 0;
  bool _positionInitialized = false;

  bool _dragging = false;
  Offset _dragStartPosition = Offset.zero;
  Offset _pointerStartPosition = Offset.zero;
  bool _movedDuringGesture = false;
  static const double _moveThreshold = 8.0; 

  @override
  void initState() {
    super.initState();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    final prefs = await SharedPreferences.getInstance();
    final xFraction = (prefs.getDouble(_xPreferenceKey) ?? 1.0).clamp(0.0, 1.0);
    final yFraction = (prefs.getDouble(_yPreferenceKey) ?? 1.0).clamp(0.0, 1.0);

    _savedXFraction = xFraction;
    _savedYFraction = yFraction;

    if (mounted) setState(() {});
  }

  double _savedXFraction = 1.0;
  double _savedYFraction = 1.0;

  Future<void> _savePosition(double maxX, double maxY) async {
    if (maxX <= 0 || maxY <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_xPreferenceKey, (_x / maxX).clamp(0.0, 1.0)),
      prefs.setDouble(_yPreferenceKey, (_y / maxY).clamp(0.0, 1.0)),
    ]);
  }

  ({double minX, double maxX, double minY, double maxY}) _bounds(
    BoxConstraints constraints,
    MediaQueryData mediaQuery,
  ) {
    final minX = _screenMargin;
    final minY = mediaQuery.padding.top + _screenMargin;
    final availableMaxX =
        constraints.maxWidth - _launcherSize - _screenMargin;
    final availableMaxY = constraints.maxHeight -
        _launcherSize -
        mediaQuery.padding.bottom -
        _screenMargin;

    return (
      minX: minX,
      maxX: availableMaxX < minX ? minX : availableMaxX,
      minY: minY,
      maxY: availableMaxY < minY ? minY : availableMaxY,
    );
  }

  // ✅ عند بدء السحب
  void _onPanStart(DragStartDetails details, BoxConstraints constraints,
      MediaQueryData mediaQuery) {
    // لو الموضع لم يُهيَّأ بعد، نستخدم الحالي
    if (!_positionInitialized) return;

    HapticFeedback.selectionClick();
    setState(() {
      _dragging = true;
      _movedDuringGesture = false;
      _dragStartPosition = Offset(_x, _y);
      _pointerStartPosition = details.globalPosition;
    });
  }

  // ✅ أثناء السحب
  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints,
      MediaQueryData mediaQuery) {
    final delta = details.globalPosition - _pointerStartPosition;

    // نتجاهل الحركات الصغيرة جداً (تمييز النقرة عن السحب)
    if (!_movedDuringGesture && delta.distance < _moveThreshold) return;

    _movedDuringGesture = true;

    final bounds = _bounds(constraints, mediaQuery);
    final newX = (_dragStartPosition.dx + delta.dx)
        .clamp(bounds.minX, bounds.maxX)
        .toDouble();
    final newY = (_dragStartPosition.dy + delta.dy)
        .clamp(bounds.minY, bounds.maxY)
        .toDouble();

    setState(() {
      _x = newX;
      _y = newY;
    });
  }

  // ✅ عند رفع الإصبع
  void _onPanEnd(DragEndDetails details, BoxConstraints constraints,
      MediaQueryData mediaQuery) {
    final wasDragging = _movedDuringGesture;
    setState(() {
      _dragging = false;
    });

    if (wasDragging) {
      // حفظ الموضع بعد السحب
      final bounds = _bounds(constraints, mediaQuery);
      _savePosition(bounds.maxX - bounds.minX, bounds.maxY - bounds.minY);
    }
    _movedDuringGesture = false;
  }

  // ✅ عند النقر (بدون سحب)
  void _onTap() {
    if (_movedDuringGesture) return; // لو كان سحباً، لا نفتح
    _openAssistant();
  }

  Future<void> _openAssistant() async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null || assistantScreenVisible.value) return;

    assistantScreenVisible.value = true;
    try {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const AssistantScreen()),
      );
    } finally {
      assistantScreenVisible.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OverlayVisibilityService.assistantVisible,
      builder: (context, launcherEnabled, _) => LayoutBuilder(
        builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final bounds = _bounds(constraints, mediaQuery);

        if (!_positionInitialized) {
          _x = bounds.minX +
              (bounds.maxX - bounds.minX) * _savedXFraction;
          _y = bounds.minY +
              (bounds.maxY - bounds.minY) * _savedYFraction;
          _positionInitialized = true;
        }

        return Stack(
          key: _overlayKey,
          children: [
            widget.child,
            ValueListenableBuilder<bool>(
              valueListenable: ApiService.isAuthenticated,
              builder: (context, signedIn, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: assistantScreenVisible,
                  builder: (context, assistantVisible, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: modalSheetOpen,
                      builder: (context, modalOpen, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: inlineModalOpen,
                          builder: (context, inlineOpen, _) {
                            final keyboardOpen =
                                mediaQuery.viewInsets.bottom > 0;
                            if (!launcherEnabled ||
                                !signedIn ||
                                assistantVisible ||
                                modalOpen ||
                                inlineOpen ||
                                keyboardOpen) {
                              return const SizedBox.shrink();
                            }

                            return Positioned(
                              left: _x,
                              top: _y,
                              child: Semantics(
                                label:
                                    'نور، المساعد الذكي. اضغط لفتحه أو اسحبه لتحريكه',
                                button: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  // ✅ نشغّل السحب المباشر + النقر معاً
                                  onTap: _onTap,
                                  onPanStart: (d) => _onPanStart(
                                      d, constraints, mediaQuery),
                                  onPanUpdate: (d) => _onPanUpdate(
                                      d, constraints, mediaQuery),
                                  onPanEnd: (d) => _onPanEnd(
                                      d, constraints, mediaQuery),
                                  child: AnimatedScale(
                                    scale: _dragging ? 1.12 : 1,
                                    duration:
                                        const Duration(milliseconds: 120),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: JisrColors.of(context).card,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _dragging
                                              ? AppColors.orange
                                              : AppColors.yellow,
                                          width: _dragging ? 3 : 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _dragging
                                                ? AppColors.orange
                                                    .withValues(alpha: 0.5)
                                                : const Color(0x33153A5B),
                                            blurRadius: _dragging ? 20 : 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const PetAvatar(size: 68),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
        },
      ),
    );
  }
}
