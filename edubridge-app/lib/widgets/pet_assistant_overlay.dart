import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/assistant_screen.dart';
import '../services/api_service.dart';
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
  double _xFraction = 1;
  double _yFraction = 1;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    final preferences = await SharedPreferences.getInstance();
    final x = preferences.getDouble(_xPreferenceKey);
    final y = preferences.getDouble(_yPreferenceKey);
    if (!mounted) return;

    setState(() {
      _xFraction = (x ?? 1).clamp(0.0, 1.0).toDouble();
      _yFraction = (y ?? 1).clamp(0.0, 1.0).toDouble();
    });
  }

  Future<void> _savePosition() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setDouble(_xPreferenceKey, _xFraction),
      preferences.setDouble(_yPreferenceKey, _yFraction),
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

  void _moveLauncher(
    LongPressMoveUpdateDetails details,
    BoxConstraints constraints,
    MediaQueryData mediaQuery,
  ) {
    final renderBox =
        _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.globalToLocal(details.globalPosition);
    final bounds = _bounds(constraints, mediaQuery);
    final x = (position.dx - _launcherSize / 2)
        .clamp(bounds.minX, bounds.maxX)
        .toDouble();
    final y = (position.dy - _launcherSize / 2)
        .clamp(bounds.minY, bounds.maxY)
        .toDouble();
    final horizontalRange = bounds.maxX - bounds.minX;
    final verticalRange = bounds.maxY - bounds.minY;

    setState(() {
      _xFraction = horizontalRange == 0
          ? 0
          : ((x - bounds.minX) / horizontalRange)
              .clamp(0.0, 1.0)
              .toDouble();
      _yFraction = verticalRange == 0
          ? 0
          : ((y - bounds.minY) / verticalRange)
              .clamp(0.0, 1.0)
              .toDouble();
    });
  }

  Future<void> _openAssistant() async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null || assistantScreenVisible.value) return;

    // Mark it visible before pushing to prevent duplicate routes on a fast tap.
    assistantScreenVisible.value = true;
    try {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const AssistantScreen()),
      );
    } finally {
      // Always restore the launcher, including when the route is removed
      // programmatically instead of with the system back button.
      assistantScreenVisible.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final bounds = _bounds(constraints, mediaQuery);
        final x =
            bounds.minX + (bounds.maxX - bounds.minX) * _xFraction;
        final y =
            bounds.minY + (bounds.maxY - bounds.minY) * _yFraction;

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
                            if (!signedIn ||
                                assistantVisible ||
                                modalOpen ||
                                inlineOpen ||
                                keyboardOpen) {
                              return const SizedBox.shrink();
                            }

                            return Positioned(
                              left: x,
                              top: y,
                              child: Semantics(
                                label:
                                    'نور، المساعد الذكي. اضغط لفتحه أو اضغط مطولاً واسحب لتحريكه',
                                button: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onLongPressStart: (_) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _dragging = true);
                                  },
                                  onLongPressMoveUpdate: (details) =>
                                      _moveLauncher(
                                    details,
                                    constraints,
                                    mediaQuery,
                                  ),
                                  onLongPressEnd: (_) {
                                    setState(() => _dragging = false);
                                    _savePosition();
                                  },
                                  child: AnimatedScale(
                                    scale: _dragging ? 1.08 : 1,
                                    duration:
                                        const Duration(milliseconds: 120),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _openAssistant,
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color:
                                                JisrColors.of(context).card,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.yellow,
                                              width: 2,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x33153A5B),
                                                blurRadius: 14,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: const PetAvatar(size: 68),
                                        ),
                                      ),
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
    );
  }
}
