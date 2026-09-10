import 'package:flutter/material.dart';

import '../screens/assistant_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/navigation.dart';
import 'pet_avatar.dart';

class PetAssistantOverlay extends StatefulWidget {
  final Widget child;

  const PetAssistantOverlay({super.key, required this.child});

  @override
  State<PetAssistantOverlay> createState() => _PetAssistantOverlayState();
}

class _PetAssistantOverlayState extends State<PetAssistantOverlay> {
  Future<void> _openAssistant() async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null || assistantScreenVisible.value) return;

    // Mark it visible before pushing to prevent duplicate routes on a fast tap.
    assistantScreenVisible.value = true;
    try {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const AssistantScreen()),
      );
    } finally {
      // Always restore the launcher, including when the route is removed
      // programmatically instead of with the system back button.
      assistantScreenVisible.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<bool>(
          valueListenable: ApiService.isAuthenticated,
          builder: (context, signedIn, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: assistantScreenVisible,
              builder: (context, assistantVisible, _) {
                final mediaQuery = MediaQuery.of(context);
                final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
                if (!signedIn ||
                    assistantVisible ||
                    keyboardOpen) {
                  return const SizedBox.shrink();
                }

                return PositionedDirectional(
                  start: 14,
                  bottom: mediaQuery.padding.bottom + 14,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openAssistant,
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: JisrColors.of(context).card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.yellow, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33153A5B),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const PetAvatar(size: 68),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
