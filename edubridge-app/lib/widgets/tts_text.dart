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
      valueListenable: TtsService.instance.tapToRead, // تغيير
      builder: (context, readingEnabled, _) {
        if (!readingEnabled || !enableTap) {
          return Text(text);
        }
        return GestureDetector(
          onTap: () => TtsService.instance.speakLine(text), // تغيير
          child: ValueListenableBuilder<String?>(
            valueListenable: TtsService.instance.activeLine, // تغيير
            builder: (context, active, _) {
              final isSpeaking = active == text;
              final effectiveStyle = isSpeaking
                  ? (style ?? const TextStyle()).copyWith(
                      color: Colors.blue,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    )
                  : style;
              return Text(text);
            },
          ),
        );
      },
    );
  }
}
  @override

// الوصول إلى _currentText — نحتاج لإضافة getter في TtsService
extension TtsServiceExt on TtsService {
  static String get _currentText => ''; // سيتم تحديثه في الخدمة
}