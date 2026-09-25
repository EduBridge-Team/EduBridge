part of 'pet_assistant_overlay.dart';

extension _PetAssistantOverlayStateView on _PetAssistantOverlayState {
  Widget buildView(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OverlayVisibilityService.assistantVisible,
      builder: (context, launcherEnabled, _) => LayoutBuilder(
        builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final bounds = _bounds(constraints, mediaQuery);

        if (!_positionInitialized) {
          _x = bounds.minX +
              (bounds.maxX - bounds.minX) * _savedXFraction;
          _y = bounds.minY +
              (bounds.maxY - bounds.minY) * _savedYFraction;
          _positionInitialized = true;
        }

        return Stack(
          key: _overlayKey,
          children: [
            widget.child,
            ValueListenableBuilder<bool>(
              valueListenable: ApiService.isAuthenticated,
              builder: (context, signedIn, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: assistantScreenVisible,
                  builder: (context, assistantVisible, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: modalSheetOpen,
                      builder: (context, modalOpen, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: inlineModalOpen,
                          builder: (context, inlineOpen, _) {
                            final keyboardOpen =
                                mediaQuery.viewInsets.bottom > 0;
                            if (!launcherEnabled ||
                                !signedIn ||
                                assistantVisible ||
                                modalOpen ||
                                inlineOpen ||
                                keyboardOpen) {
                              return const SizedBox.shrink();
                            }

                            return Positioned(
                              left: _x,
                              top: _y,
                              child: Semantics(
                                label:
                                    'نور، المساعد الذكي. اضغط لفتحه أو اسحبه لتحريكه',
                                button: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  // ✅ نشغّل السحب المباشر + النقر معاً
                                  onTap: _onTap,
                                  onPanStart: (d) => _onPanStart(
                                      d, constraints, mediaQuery),
                                  onPanUpdate: (d) => _onPanUpdate(
                                      d, constraints, mediaQuery),
                                  onPanEnd: (d) => _onPanEnd(
                                      d, constraints, mediaQuery),
                                  child: AnimatedScale(
                                    scale: _dragging ? 1.12 : 1,
                                    duration:
                                        const Duration(milliseconds: 120),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: JisrColors.of(context).card,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _dragging
                                              ? AppColors.navy
                                              : AppColors.teal.withValues(alpha: 0.75),
                                          width: _dragging ? 3 : 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _dragging
                                                ? AppColors.navy
                                                    .withValues(alpha: 0.34)
                                                : AppColors.teal
                                                    .withValues(alpha: 0.22),
                                            blurRadius: _dragging ? 20 : 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const PetAvatar(size: 76),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
        },
      ),
    );
  
  }
}
