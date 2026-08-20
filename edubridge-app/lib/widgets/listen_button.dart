// زر «القراءة باللمس» — يُفعّل وضعاً يقرأ أي سطر يلمسه المستخدم صوتياً بالعربية.
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme.dart';

class ListenButton extends StatelessWidget {
  // لون الأيقونة (أبيض فوق الرأس المتدرّج مثلاً)
  final Color? color;

  const ListenButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.instance.tapToRead,
      builder: (context, on, _) {
        return IconButton(
          icon: Icon(
            on ? Icons.touch_app : Icons.volume_up,
            size: 28,
            // عند التفعيل نُبرز الأيقونة (أخضر) ما لم يُطلب لون ثابت (أبيض)
            color: on ? (color ?? AppColors.green) : color,
          ),
          tooltip: on
              ? 'إيقاف القراءة باللمس'
              : 'القراءة باللمس: اضغط ثم المس أي سطر',
          onPressed: () async {
            await TtsService.instance.toggleTapToRead();
            if (!context.mounted) return;
            final isOn = TtsService.instance.tapToRead.value;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text(
                  isOn
                      ? 'وضع القراءة باللمس مُفعّل — المس أي سطر لقراءته 🔊'
                      : 'أُوقف وضع القراءة باللمس',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
