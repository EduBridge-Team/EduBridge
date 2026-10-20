import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/tts_service.dart';
import '../theme.dart';

class ListenButton extends StatelessWidget {
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
            color: on ? (color ?? AppColors.green) : color,
          ),
          tooltip: on
              ? context.l10n.tapReadStopTooltip
              : context.l10n.tapReadStartTooltip,
          onPressed: () async {
            await TtsService.instance.toggleTapToRead();
            if (!context.mounted) return;
            final isOn = TtsService.instance.tapToRead.value;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text(
                  isOn
                      ? context.l10n.tapReadEnabledNotice
                      : context.l10n.tapReadDisabledNotice,
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
