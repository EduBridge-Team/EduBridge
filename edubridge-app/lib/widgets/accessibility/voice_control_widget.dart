// lib/widgets/adaptive/voice_control_widget.dart
// زر تحكم صوتي عائم للأوامر
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../services/voice_command_service.dart';
import '../../theme.dart';
import '../../utils/adaptive_helper.dart';

class VoiceControlWidget extends StatefulWidget {
  final Widget child;

  const VoiceControlWidget({super.key, required this.child});

  @override
  State<VoiceControlWidget> createState() => _VoiceControlWidgetState();
}

class _VoiceControlWidgetState extends State<VoiceControlWidget> {
  final _service = VoiceCommandService.instance;
  bool _positioned = false;
  double _x = 0;
  double _y = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        // ✅ يظهر فقط عند تفعيل "التحكم الصوتي"
        final enabled = profile.voiceControl ||
            profile.type == DisabilityType.motorDisability ||
            profile.type == DisabilityType.blind ||
            profile.keyboardOnlyNavigation;

        if (!enabled) return widget.child;

        return LayoutBuilder(
          builder: (context, constraints) {
            if (!_positioned) {
              _x = constraints.maxWidth - 90;
              _y = constraints.maxHeight - 200;
              _positioned = true;
            }

            return Stack(
              children: [
                widget.child,
                Positioned(
                  left: _x,
                  top: _y,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _x = (_x + details.delta.dx)
                            .clamp(0, constraints.maxWidth - 80);
                        _y = (_y + details.delta.dy)
                            .clamp(0, constraints.maxHeight - 80);
                      });
                    },
                    child: _buildVoiceButton(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVoiceButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.isListening,
      builder: (context, listening, _) {
        return AnimatedContainer(
          duration: AdaptiveHelper.animationDuration,
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: listening ? AppColors.red : AppColors.purple,
            border: Border.all(
              color: listening ? Colors.red.shade200 : Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (listening ? AppColors.red : AppColors.purple)
                    .withValues(alpha: 0.5),
                blurRadius: listening ? 24 : 12,
                spreadRadius: listening ? 6 : 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                AdaptiveHelper.hapticFeedback();
                if (listening) {
                  _service.stopListening();
                } else {
                  _service.startListening();
                }
              },
              child: Icon(
                listening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }
}