// زر ضخم جداً مع نطق تلقائي عند اللمس — مناسب لمتلازمة داون
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';

class LargeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const LargeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = AccessibilityService.instance.profile.value;
    final size = p.extraLargeTouchTargets ? 100.0 : 64.0;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          if (p.autoReadOnTap) {
            TtsService.instance.speakLine(label);
          }
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFF1AA9B2),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: size * 0.42),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}