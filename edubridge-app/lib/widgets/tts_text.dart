// نص قابل للقراءة — عند تفعيل وضع القراءة، النقر يقرأ المحتوى صوتياً
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class TtsText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TtsText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.enabled,
      builder: (context, ttsOn, _) {
        final baseStyle = style ?? DefaultTextStyle.of(context).style;
        if (!ttsOn) {
          return Text(
            text,
            style: baseStyle,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
        }
        return GestureDetector(
          onTap: () => TtsService.speak(text),
          child: Text(
            text,
            style: baseStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: baseStyle.color?.withValues(alpha: 0.5),
            ),
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          ),
        );
      },
    );
  }
}
