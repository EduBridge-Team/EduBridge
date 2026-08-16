// زر تفعيل/إيقاف وضع القراءة الصوتية
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class TtsToggleButton extends StatelessWidget {
  const TtsToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.enabled,
      builder: (context, on, _) => IconButton(
        icon: Icon(
          on ? Icons.record_voice_over : Icons.volume_off_outlined,
          color: on ? const Color(0xFFFFC23C) : Colors.white,
        ),
        tooltip: on ? 'إيقاف القراءة' : 'تفعيل القراءة',
        onPressed: () => TtsService.toggle(),
      ),
    );
  }
}
