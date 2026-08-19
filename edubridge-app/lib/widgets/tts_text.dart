// Widget محسّن للنصوص — يقرأ الصوت عند النقر إذا كان الوضع مفعّلاً
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

/// نص عادي + قراءة صوتية عند النقر
/// الاستخدام: TtsText('النص هنا')
class TtsText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableTap; // هل يقرأ عند النقر؟

  const TtsText(
    this.text, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableTap = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.enabled,
      builder: (context, readingEnabled, _) {
        // إذا كان الوضع مفعّلاً، اجعل النص قابل للنقر
        if (!readingEnabled || !enableTap) {
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
        }

        // نص قابل للنقر مع مؤشر يد
        return GestureDetector(
          onTap: () => TtsService.speak(text),
          child: ValueListenableBuilder<bool>(
            valueListenable: TtsService.isSpeaking,
            builder: (context, speaking, _) {
              // تغيير اللون إذا كان يقرأ الآن
              final effectiveStyle = speaking && text == TtsService.currentText
                  ? (style ?? const TextStyle()).copyWith(
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

// الوصول إلى _currentText — نحتاج لإضافة getter في TtsService
extension TtsServiceExt on TtsService {
  static String get _currentText => ''; // سيتم تحديثه في الخدمة
}