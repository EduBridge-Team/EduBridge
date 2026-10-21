import '../../l10n/l10n.dart';
// lib/widgets/adaptive/adaptive_button.dart
// زر يتكيّف تلقائياً: حجم، نطق، اهتزاز
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';

enum AdaptiveButtonStyle { filled, outlined, text }

class AdaptiveButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AdaptiveButtonStyle style;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;
  final bool enableReadOnTap;
  final double? fontSize;
  final bool isBusy;
  final String? speechLanguageCode;
  const AdaptiveButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.style = AdaptiveButtonStyle.filled,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.enableReadOnTap = true,
    this.fontSize,
    this.isBusy = false,
    this.speechLanguageCode,
  });

  @override
  State<AdaptiveButton> createState() => _AdaptiveButtonState();
}

class _AdaptiveButtonState extends State<AdaptiveButton> {
  Timer? _tapGuard;
  bool _locked = false;

  @override
  void dispose() {
    _tapGuard?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        final height = AdaptiveHelper.buttonHeight;
        final fontSize = widget.fontSize ?? AdaptiveHelper.bodyFontSize;
        final iconSize = AdaptiveHelper.iconSize * 0.8;

        // الألوان
        final effectiveBg = widget.backgroundColor ??
            AdaptiveHelper.accentColor(context);
        final effectiveFg =
            widget.foregroundColor ?? Colors.white;

        // عند اللمس
        void handleTap() {
          if (widget.onPressed == null || widget.isBusy || _locked) return;
          setState(() => _locked = true);
          _tapGuard = Timer(const Duration(milliseconds: 350), () {
            if (mounted) setState(() => _locked = false);
          });

          // اهتزاز (للصمّ)
          AdaptiveHelper.hapticFeedback();

          // نطق النص قبل التنفيذ
          if (widget.enableReadOnTap && profile.autoReadOnTap && !profile.sensoryCalmMode) {
            AdaptiveHelper.speak(widget.label,
              languageCode: widget.speechLanguageCode ?? context.l10n.localeName);
          }

          widget.onPressed!();
        }

        Widget button;
        switch (widget.style) {
          case AdaptiveButtonStyle.filled:
            button = ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBg,
                foregroundColor: effectiveFg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                minimumSize: Size(48, height),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AdaptiveHelper.cardRadius - 4),
                ),
              ),
              onPressed: widget.onPressed == null || widget.isBusy || _locked ? null : handleTap,
              child: _buildChild(fontSize, iconSize),
            );
            break;

          case AdaptiveButtonStyle.outlined:
            button = OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: effectiveBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                minimumSize: Size(48, height),
                side: BorderSide(
                  color: effectiveBg,
                  width: AdaptiveHelper.borderWidth,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AdaptiveHelper.cardRadius - 4),
                ),
              ),
              onPressed: widget.onPressed == null || widget.isBusy || _locked ? null : handleTap,
              child: _buildChild(fontSize, iconSize),
            );
            break;

          case AdaptiveButtonStyle.text:
            button = TextButton(
              style: TextButton.styleFrom(
                foregroundColor: effectiveBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: Size(48, height),
              ),
              onPressed: widget.onPressed == null || widget.isBusy || _locked ? null : handleTap,
              child: _buildChild(fontSize, iconSize),
            );
            break;
        }

        if (!widget.fullWidth) return button;
        return SizedBox(width: double.infinity, child: button);
      },
    );
  }

  Widget _buildChild(double fontSize, double iconSize) {
    final text = Text(
      widget.label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );

    if (AdaptiveHelper.profile.iconOnlyMode && widget.icon != null && !widget.isBusy) {
      return Tooltip(message: widget.label, child: Semantics(
        label: widget.label, excludeSemantics: true,
        child: Icon(widget.icon, size: iconSize),
      ));
    }
    if (widget.isBusy) {
      return Semantics(label: context.l10n.childLessonsWorking, liveRegion: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10), Flexible(child: text),
        ]));
    }
    if (widget.icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, size: iconSize),
        const SizedBox(width: 10),
        Flexible(child: text),
      ],
    );
  }
}