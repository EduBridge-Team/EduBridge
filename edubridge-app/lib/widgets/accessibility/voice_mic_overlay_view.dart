part of 'voice_mic_overlay.dart';

extension _VoiceMicOverlayStateView on _VoiceMicOverlayState {
  Widget buildView(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OverlayVisibilityService.microphoneVisible,
      builder: (context, microphoneEnabled, _) => LayoutBuilder(
        builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final b = _bounds(constraints, mq);
        final x = b.minX + (b.maxX - b.minX) * _xFraction;
        final y = b.minY + (b.maxY - b.minY) * _yFraction;

        return Stack(
          key: _overlayKey,
          children: [
            widget.child,
            // ✅ التحقق من الدور: يظهر فقط لولي الأمر
            ValueListenableBuilder<String?>(
              valueListenable: ApiService.userRole,
              builder: (context, role, _) {
                // ❌ ليس ولي أمر → لا تعرض شيئاً
                if (role != 'parent') return const SizedBox.shrink();

                return ValueListenableBuilder<bool>(
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
                                    mq.viewInsets.bottom > 0;
                                if (!microphoneEnabled ||
                                    !signedIn ||
                                    assistantVisible ||
                                    modalOpen ||
                                    inlineOpen ||
                                    keyboardOpen ||
                                    !_positionReady) {
                                  return const SizedBox.shrink();
                                }

                                return Positioned(
                                  left: x,
                                  top: y,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // شارة وضع القراءة
                                      const ReadModeBadge(),
                                      // فقاعة "ما سمعته"
                                      _ListeningBubble(service: _service),
                                      // الزر
                                      GestureDetector(
                                        onTap: _onTap,
                                        onLongPressStart: (_) {
                                          HapticFeedback
                                              .selectionClick();
                                          setState(
                                              () => _dragging = true);
                                        },
                                        onLongPressMoveUpdate: (d) =>
                                            _onPanUpdate(
                                                d, constraints, mq),
                                        onLongPressEnd: (_) {
                                          setState(
                                              () => _dragging = false);
                                          _savePosition();
                                          HapticFeedback
                                              .lightImpact();
                                        },
                                        child: _MicButton(
                                            service: _service),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
