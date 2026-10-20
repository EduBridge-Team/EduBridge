import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/tts_service.dart';

class TtsToggleButton extends StatelessWidget {
  const TtsToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.instance.tapToRead,
      builder: (context, on, _) => IconButton(
        icon: Icon(
          on ? Icons.record_voice_over : Icons.volume_off_outlined,
          color: on ? const Color(0xFFFFC23C) : Colors.white,
        ),
        tooltip: on ? context.l10n.readingStopTooltip : context.l10n.readingStartTooltip,
        onPressed: () => TtsService.instance.toggleTapToRead(),
      ),
    );
  }
}