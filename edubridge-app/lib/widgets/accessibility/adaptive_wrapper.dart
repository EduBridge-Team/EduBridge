import '../../l10n/l10n.dart';
// lib/widgets/accessibility/adaptive_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';

/// غلاف شامل يطبّق كل ميزات التكييف على أي شاشة
class AdaptiveWrapper extends StatefulWidget {
  final Widget child;
  final String? screenTitle;
  final String? speechLanguageCode;

  const AdaptiveWrapper({
    super.key,
    required this.child,
    this.screenTitle,
    this.speechLanguageCode,
  });

  @override
  State<AdaptiveWrapper> createState() => _AdaptiveWrapperState();
}

class _AdaptiveWrapperState extends State<AdaptiveWrapper> {
  final _focusNode = FocusNode();
  String? _announcedTitle;
  String? _announcedLanguage;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, child) {
        Widget result = widget.child;

        // Keep the EduBridge palette for every adaptation.

        // ═══════════════════════════════════════════════
        //  1. وضع الأيقونات فقط (iconOnlyMode)
        // ═══════════════════════════════════════════════
        if (profile.iconOnlyMode) {
          result = _IconOnlyWrapper(child: result);
        }

        // ═══════════════════════════════════════════════
        //  2. إخفاء الصور (textOnlyMode)
        // ═══════════════════════════════════════════════
        if (profile.textOnlyMode) {
          result = _TextOnlyWrapper(child: result);
        }

       

        // ═══════════════════════════════════════════════
        //  4. قارئ الشاشة (screenReaderOptimized)
        // ═══════════════════════════════════════════════
        if (profile.screenReaderOptimized) {
          result = Semantics(
            container: true,
            explicitChildNodes: true,
            label: widget.screenTitle,
            child: result,
          );
        }

        // ═══════════════════════════════════════════════
        //  5. تحكم بلوحة المفاتيح (keyboardOnlyNavigation)
        // ═══════════════════════════════════════════════
        if (profile.keyboardOnlyNavigation ||
            profile.keyboardShortcuts ||
            profile.switchControl) {
          result = Focus(
            autofocus: true,
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: result,
          );
        }

        // ═══════════════════════════════════════════════
        //  7. تكرار المحتوى (repetitionMode)
        // ═══════════════════════════════════════════════
        final title = widget.screenTitle;
        final language = widget.speechLanguageCode ?? context.l10n.localeName;
        if (profile.repetitionMode && title != null &&
            (_announcedTitle != title || _announcedLanguage != language)) {
          _announcedTitle = title;
          _announcedLanguage = language;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _announcedTitle == title && _announcedLanguage == language &&
                AccessibilityService.instance.profile.value.repetitionMode &&
                AdaptiveHelper.shouldReadOnTap) {
              AdaptiveHelper.speak(title, languageCode: language);
            }
          });
        }

        if (!profile.repetitionMode) {
          _announcedTitle = null;
          _announcedLanguage = null;
        }
        return FocusTraversalGroup(child: result);
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Escape → رجوع
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        return KeyEventResult.handled;
      }
    }


    return KeyEventResult.ignored;
  }


}

// ═══════════════════════════════════════════════════════════
//  غلاف وضع الأيقونات
// ═══════════════════════════════════════════════════════════
class _IconOnlyWrapper extends StatelessWidget {
  final Widget child;
  const _IconOnlyWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return IconOnlyScope(enabled: true, child: child);
  }
}

class IconOnlyScope extends InheritedWidget {
  final bool enabled;
  const IconOnlyScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<IconOnlyScope>()?.enabled ?? false;
  }

  @override
  bool updateShouldNotify(IconOnlyScope old) => old.enabled != enabled;
}

// ═══════════════════════════════════════════════════════════
//  غلاف الوضع النصي (يخفي الصور)
// ═══════════════════════════════════════════════════════════
class _TextOnlyWrapper extends StatelessWidget {
  final Widget child;
  const _TextOnlyWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return TextOnlyScope(enabled: true, child: child);
  }
}

class TextOnlyScope extends InheritedWidget {
  final bool enabled;
  const TextOnlyScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TextOnlyScope>()?.enabled ?? false;
  }

  @override
  bool updateShouldNotify(TextOnlyScope old) => old.enabled != enabled;
}