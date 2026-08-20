import 'package:edubridge_app/services/tts_service.dart';
import 'package:flutter/material.dart';

class TtsToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool
    >(
      valueListenable: TtsService.instance.tapToRead, // تغيير
      builder: (context, on, _) => IconButton(
        icon: Icon(
          on ? Icons.record_voice_over : Icons.volume_off_outlined,
          color: on ? const Color(0xFFFFC23C) : Colors.white,
        ),
        tooltip: on ? 'إيقاف القراءة' : 'تفعيل القراءة',
        onPressed: () => TtsService.instance.toggleTapToRead(), // تغيير
      ),
    );
  }
}