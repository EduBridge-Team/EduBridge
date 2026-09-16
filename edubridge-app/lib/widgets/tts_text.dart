import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class TtsText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableTap; // هل يقرأ عند النقر؟

  const TtsText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.instance.tapToRead,
      builder: (context, readingEnabled, _) {
        if (!readingEnabled || !enableTap) {
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
        }

        return GestureDetector(
          onTap: () => TtsService.instance.speakLine(text),
          child: ValueListenableBuilder<String?>(
            valueListenable: TtsService.instance.activeLine,
            builder: (context, active, _) {
              final isSpeaking = active == text;
              final baseStyle = style ?? const TextStyle();
              final effectiveStyle = isSpeaking
                  ? baseStyle.copyWith(
                      color: Colors.blue,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    )
                  : style;

              return Text(
                text,
                style: effectiveStyle,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: overflow,
              );
            },
          ),
        );
      },
    );
  }
}