
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme.dart';

class Speakable extends StatelessWidget {
  // النص المقروء صوتياً
  final String text;
  final Widget child;

  final VoidCallback? onTap;

  final double radius;

  const Speakable({
    super.key,
    required this.text,
    required this.child,
    this.onTap,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final tts = TtsService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: tts.tapToRead,
      builder: (context, reading, _) {
        if (!reading) {
          if (onTap == null) return child;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: child,
          );
        }

        return ValueListenableBuilder<String?>(
          valueListenable: tts.activeLine,
          builder: (context, active, __) {
            final c = JisrColors.of(context);
            final isActive = active == text;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tts.speakLine(text),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  color: isActive ? c.tintGreen : null,
                  border: Border.all(
                    color: isActive ? AppColors.green : c.line,
                    width: isActive ? 2.5 : 1.2,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
