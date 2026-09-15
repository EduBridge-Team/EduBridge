// شارة عائمة تُظهر "وضع القراءة مُفعّل"
// تظهر فوق زر المايك مباشرة حين يكون tapToRead مفعّلاً
import 'package:flutter/material.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';


class ReadModeBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const ReadModeBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.instance.tapToRead,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap ?? () => TtsService.instance.toggleTapToRead(),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'وضع القراءة مُفعّل',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}