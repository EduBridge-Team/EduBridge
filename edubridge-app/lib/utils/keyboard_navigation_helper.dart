// lib/utils/keyboard_navigation_helper.dart
// مساعد التنقل بلوحة المفاتيح — للأطفال ذوي الإعاقات الحركية
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import 'adaptive_helper.dart';

/// غلاف يضيف اختصارات لوحة المفاتيح للشاشة
class KeyboardNavigationWrapper extends StatefulWidget {
  final Widget child;
  final Map<LogicalKeyboardKey, VoidCallback> shortcuts;

  const KeyboardNavigationWrapper({
    super.key,
    required this.child,
    this.shortcuts = const {},
  });

  @override
  State<KeyboardNavigationWrapper> createState() =>
      _KeyboardNavigationWrapperState();
}

class _KeyboardNavigationWrapperState extends State<KeyboardNavigationWrapper> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        // ✅ تفعيل الاختصارات فقط عند الحاجة
        if (!profile.keyboardShortcuts &&
            !profile.keyboardOnlyNavigation &&
            profile.type != DisabilityType.motorDisability) {
          return widget.child;
        }

        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              // ✅ اختصارات مخصصة
              if (widget.shortcuts.containsKey(event.logicalKey)) {
                widget.shortcuts[event.logicalKey]?.call();
                return KeyEventResult.handled;
              }

              // ✅ Escape → رجوع
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                  return KeyEventResult.handled;
                }
              }

              // ✅ Alt+1 .. Alt+9 → اختصارات عامة
              if (HardwareKeyboard.instance.isAltPressed) {
                final num = _numberFromKey(event.logicalKey);
                if (num != null) {
                  _onNumberShortcut(num);
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: widget.child,
        );
      },
    );
  }

  // ✅ إصلاح: switch بدل const map
  //    لأن LogicalKeyboardKey.digit* ليست const في Flutter 3.24+
  int? _numberFromKey(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.digit1:
        return 1;
      case LogicalKeyboardKey.digit2:
        return 2;
      case LogicalKeyboardKey.digit3:
        return 3;
      case LogicalKeyboardKey.digit4:
        return 4;
      case LogicalKeyboardKey.digit5:
        return 5;
      case LogicalKeyboardKey.digit6:
        return 6;
      case LogicalKeyboardKey.digit7:
        return 7;
      case LogicalKeyboardKey.digit8:
        return 8;
      case LogicalKeyboardKey.digit9:
        return 9;
      default:
        return null;
    }
  }

  void _onNumberShortcut(int num) {
    AdaptiveHelper.hapticFeedback();
    // يمكن تخصيصها لاحقاً
  }
}

/// زر يدعم Focus + Enter (للتنقل بلوحة المفاتيح)
class FocusableAdaptiveButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const FocusableAdaptiveButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  State<FocusableAdaptiveButton> createState() =>
      _FocusableAdaptiveButtonState();
}

class _FocusableAdaptiveButtonState extends State<FocusableAdaptiveButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _focused = hasFocus);
        if (hasFocus) AdaptiveHelper.hapticFeedback();
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: AdaptiveHelper.animationDuration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AdaptiveHelper.cardRadius),
          border: Border.all(
            color: _focused
                ? AdaptiveHelper.accentColor(context)
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(
              double.infinity,
              AdaptiveHelper.buttonHeight,
            ),
          ),
          onPressed: widget.onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: AdaptiveHelper.iconSize * 0.8),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}